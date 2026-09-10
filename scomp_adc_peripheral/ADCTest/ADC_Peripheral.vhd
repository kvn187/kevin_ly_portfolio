library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ADC_PERIPHERAL is
    generic (
        CLK_DIV         : positive := 2;        -- how quick ADC serial clock toggles
        CONV_HIGH_CLKS  : positive := 1;        -- how long CONVST stays high
        CONV_WAIT_CLKS  : positive := 80;       -- how long wait after CONVST before data shift
        ACQ_HOLD_CLKS   : positive := 4         -- how long hold after CONVST after data shift
    );
    port (
        -- SCOMP bus
        CLOCK       : in    std_logic;          -- system clock
        RESETN      : in    std_logic;          -- active low reset
        IO_READ     : in    std_logic;          -- SCOMP read from I/O addr
        IO_WRITE    : in    std_logic;          -- SCOMP write to I/O addr
        IO_ADDR     : in    std_logic_vector(10 downto 0);    -- 11bit I/O addr bus
        IO_DATA     : inout std_logic_vector(15 downto 0);    -- 16bit data bus
        -- when write SCOMP drive and peripheral reads
        -- when read peripheral drive and SCOMP reads

        -- LTC2308 pins
        ADC_SCK     : out   std_logic;          -- serial clock to ADC
        ADC_CONVST  : out   std_logic;          -- CONVST start to ADC
        ADC_SDI     : out   std_logic;          -- serial data input to ADC
        ADC_SDO     : in    std_logic           -- serial data output to ADC
    );
end entity ADC_PERIPHERAL;

architecture rtl of ADC_PERIPHERAL is

    -- Register Map
    constant ADC_CTRL_ADDR    : integer := 16#0C0#; -- 0xC0
    constant ADC_STATUS_ADDR  : integer := 16#0C1#; -- 0xC1
    constant ADC_DATA_ADDR    : integer := 16#0C2#; -- 0xC2
    constant ADC_CHANNEL_ADDR : integer := 16#0C3#; -- 0xC3

    -- Finite State Machine
    type state_type is (IDLE, CONV_HIGH, CONV_WAIT, SHIFT, ACQ_HOLD, DONE); -- states
    signal state : state_type := IDLE;          -- start in idle

    -- Program Registers
    signal channel_reg     : std_logic_vector(2 downto 0) := "000"; -- 3bit select ADC channel
    signal ready_reg       : std_logic := '0';  -- conversion result is ready
    signal busy_reg        : std_logic := '0';  -- ADC is busy
    signal data_reg        : std_logic_vector(11 downto 0) := (others => '0'); -- store 12bit ADC sample

    -- Flags
    signal start_req       : std_logic := '0';  -- latch request begin conversion
    signal clear_ready_req : std_logic := '0';  -- latch request clear ready bit

    -- Address Decode
    signal addr_u          : integer range 0 to 2047;    -- to compare IO addr to int constants
    signal wr_ctrl_sel     : std_logic;         -- SCOMP write ctrl register = high
    signal wr_chan_sel     : std_logic;         -- SCOMP write channel register = high
    signal rd_status_sel   : std_logic;         -- SCOMP read status register = high
    signal rd_data_sel     : std_logic;         -- SCOMP read data register = high
    signal rd_chan_sel     : std_logic;         -- SCOMP read channel register = high
    signal read_hit        : std_logic;         -- read register matches = high / true

    -- read data bus
    signal read_data       : std_logic_vector(15 downto 0) := (others => '0');

    -- SPI / LTC2308 internal signals
    signal din6            : std_logic_vector(5 downto 0);    -- 6bit command to ADC
    signal tx_reg          : std_logic_vector(11 downto 0) := (others => '0');    -- transmit shift register
    signal rx_reg          : std_logic_vector(11 downto 0) := (others => '0');    -- receive shift register
    signal sdi_reg         : std_logic := '0';  -- current value drive onto ADC_SDI
    signal sclk_int        : std_logic := '0';  -- internal serial clock signal
    signal convst_reg      : std_logic := '0';  -- internal register for ADC_CONVST

    signal clk_cnt         : integer range 0 to CLK_DIV - 1 := 0;    -- divide system clock = SPI clock
    signal conv_high_cnt   : integer range 0 to CONV_HIGH_CLKS - 1 := 0;    -- counts how long CONVST stays high
    signal conv_wait_cnt   : integer range 0 to CONV_WAIT_CLKS - 1 := 0;    -- counts wait time after conversion start
    signal acq_hold_cnt    : integer range 0 to ACQ_HOLD_CLKS - 1 := 0;     -- counts hold time after shift
    signal bit_cnt         : integer range 0 to 11 := 0;    -- count how many SPI bits shift (12bit)

    signal sclk_rise_evt   : std_logic;         -- SPI clock rise
    signal sclk_fall_evt   : std_logic;         -- SPI clock fall
    
begin

    -- External Outputs, connect internal signals to external ADC pins
    ADC_SCK    <= sclk_int;
    ADC_CONVST <= convst_reg;
    ADC_SDI    <= sdi_reg;

    -- LTC2308 6bit command
    -- din6 = S/D, O/S, S1, S0, UNI, SLP
    -- S/D=1 single-ended
    -- O/S,S1,S0 = channel_reg
    -- UNI=1 unipolar
    -- SLP=0 nap mode
    din6 <= '1' & channel_reg & '1' & '0';

    -- Address Decode, 11bit addr to int
    addr_u        <= to_integer(unsigned(IO_ADDR));

    wr_ctrl_sel   <= '1' when (IO_WRITE = '1' and addr_u = ADC_CTRL_ADDR)    else '0';    -- ctrl register
    wr_chan_sel   <= '1' when (IO_WRITE = '1' and addr_u = ADC_CHANNEL_ADDR) else '0';    -- channel register

    rd_status_sel <= '1' when (IO_READ  = '1' and addr_u = ADC_STATUS_ADDR)  else '0';    -- status register
    rd_data_sel   <= '1' when (IO_READ  = '1' and addr_u = ADC_DATA_ADDR)    else '0';    -- data register
    rd_chan_sel   <= '1' when (IO_READ  = '1' and addr_u = ADC_CHANNEL_ADDR) else '0';    -- channel register

    read_hit      <= rd_status_sel or rd_data_sel or rd_chan_sel;    -- if valid read occurs

    -- SCK edge flags
    -- Rising Edge Event
    sclk_rise_evt <= '1'
        when (state = SHIFT and clk_cnt = CLK_DIV - 1 and sclk_int = '0')
        else '0';

    -- Falling Edge Event
    sclk_fall_evt <= '1'
        when (state = SHIFT and clk_cnt = CLK_DIV - 1 and sclk_int = '1')
        else '0';

    -- READ MUX
    process(ready_reg, busy_reg, data_reg, channel_reg, rd_status_sel, rd_data_sel, rd_chan_sel)
    begin
        read_data <= (others => '0');

        if rd_status_sel = '1' then
            -- bit0 = READY, bit1 = BUSY
            read_data <= (15 downto 2 => '0') & busy_reg & ready_reg;

        elsif rd_data_sel = '1' then
            -- bit11 0 = SAMPLE (zero-extended to 16bits)
            read_data <= (15 downto 12 => '0') & data_reg;

        elsif rd_chan_sel = '1' then
            -- bit2 0 = CHANNEL
            read_data <= (15 downto 3 => '0') & channel_reg;
        end if;
    end process;

    -- Tri-State Bus Drive
    IO_DATA <= read_data when read_hit = '1' else (others => 'Z');    -- drives IO_DATA, else Z

    -- Bus Interface
    process(CLOCK, RESETN)
    begin
        if RESETN = '0' then
            channel_reg     <= "000";
            start_req       <= '0';
            clear_ready_req <= '0';

        elsif rising_edge(CLOCK) then
            clear_ready_req <= '0';

            -- once the request has been accepted, clear the start request
            if state = CONV_HIGH then
                start_req <= '0';
            end if;

            -- ADC_CTRL write
            -- bit0 = START
            -- bit1 = CLEAR_READY
            if wr_ctrl_sel = '1' then
                if IO_DATA(0) = '1' then
                    start_req <= '1';
                end if;

                if IO_DATA(1) = '1' then
                    clear_ready_req <= '1';
                end if;
            end if;

            -- ADC_CHANNEL write
            -- bit2 0 = channel number
            if wr_chan_sel = '1' then
                channel_reg <= IO_DATA(2 downto 0);
            end if;
        end if;
    end process;

    -- CTRL FSM Process
    process(CLOCK, RESETN)
    begin
        if RESETN = '0' then    -- initialize
            state         <= IDLE;
            ready_reg     <= '0';
            busy_reg      <= '0';
            convst_reg    <= '0';
            conv_high_cnt <= 0;
            conv_wait_cnt <= 0;
            acq_hold_cnt  <= 0;
            bit_cnt       <= 0;

        elsif rising_edge(CLOCK) then

            if clear_ready_req = '1' then
                ready_reg <= '0';
            end if;

            case state is
                when IDLE =>
                    busy_reg   <= '0';
                    convst_reg <= '0';

                    if start_req = '1' then     -- if busy, assert CONVST, load counter to hold high
                        busy_reg      <= '1';
                        convst_reg    <= '1';
                        conv_high_cnt <= CONV_HIGH_CLKS - 1;
                        state         <= CONV_HIGH;
                    end if;

                when CONV_HIGH =>
                    busy_reg   <= '1';          -- stay busy
                    convst_reg <= '1';          -- keep CONVST high

                    if conv_high_cnt = 0 then
                        convst_reg    <= '0';
                        conv_wait_cnt <= CONV_WAIT_CLKS - 1;
                        state         <= CONV_WAIT;
                    else
                        conv_high_cnt <= conv_high_cnt - 1;
                    end if;

                when CONV_WAIT =>
                    busy_reg   <= '1';
                    convst_reg <= '0';

                    -- ADC conversion time gap
                    if conv_wait_cnt = 0 then
                        bit_cnt <= 0;
                        state   <= SHIFT;
                    else
                        conv_wait_cnt <= conv_wait_cnt - 1;
                    end if;

                when SHIFT =>
                    busy_reg   <= '1';
                    convst_reg <= '0';

                    -- 1 bit received, if it was bit11 thats 12bits total, load hold counter, else increment
                    if sclk_rise_evt = '1' then
                        if bit_cnt = 11 then
                            acq_hold_cnt <= ACQ_HOLD_CLKS - 1;
                            state        <= ACQ_HOLD;
                        else
                            bit_cnt <= bit_cnt + 1;
                        end if;
                    end if;

                when ACQ_HOLD =>    
                    busy_reg   <= '1';
                    convst_reg <= '0';

                    if acq_hold_cnt = 0 then
                        ready_reg <= '1';       -- mark data ready
                        state     <= DONE;
                    else
                        acq_hold_cnt <= acq_hold_cnt - 1;
                    end if;

                when DONE =>
                    busy_reg   <= '0';          -- no longer busy
                    convst_reg <= '0';          -- CONVST low
                    state      <= IDLE;         -- next state is IDLE
            end case;
        end if;
    end process;

    -- SCK Generation
    process(CLOCK, RESETN)
    begin
        if RESETN = '0' then
            clk_cnt  <= 0;                     -- divider counter = 0
            sclk_int <= '0';                   -- SPI clock = 0

        elsif rising_edge(CLOCK) then
            if state = SHIFT then
                if clk_cnt = CLK_DIV - 1 then
                    clk_cnt  <= 0;             -- reset divider
                    sclk_int <= not sclk_int;  -- SPI clock toggle
                else
                    clk_cnt <= clk_cnt + 1;
                end if;
            else
                clk_cnt  <= 0;                 -- reset divider
                sclk_int <= '0';               -- force SPI clock low
            end if;
        end if;
    end process;

    -- SPI Datapath
    process(CLOCK, RESETN)
    begin
        if RESETN = '0' then
            tx_reg   <= (others => '0');       -- transmit register = 0
            rx_reg   <= (others => '0');       -- receive register = 0
            data_reg <= (others => '0');       -- final data register = 0
            sdi_reg  <= '0';                   -- serial data output = 0

        elsif rising_edge(CLOCK) then
            case state is
                when IDLE =>
                    if start_req = '1' then
                        tx_reg  <= din6 & "000000";    -- top 6bits are command bits
                        rx_reg  <= (others => '0');
                        sdi_reg <= din6(5);    -- before shift start, first output bit on SDI line
                    end if;

                when SHIFT =>
                    -- output updates on falling edge
                    if sclk_fall_evt = '1' then
                        tx_reg  <= tx_reg(10 downto 0) & '0';    -- insert 0 at LSB
                        sdi_reg <= tx_reg(10);    -- update with next outgoing bit
                    end if;

                    -- input samples on rising edge
                    if sclk_rise_evt = '1' then
                        rx_reg <= rx_reg(10 downto 0) & ADC_SDO;    -- shift left and append ADC_SD0 bit
                    end if;

                when ACQ_HOLD =>
                    data_reg <= rx_reg;    -- copy received 12bit value in

                when others =>
                    null;
            end case;
        end if;
    end process;

end architecture rtl;
