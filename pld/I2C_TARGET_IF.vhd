library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity I2C_TARGET_IF is
    port (
        -- System --
        RESET_n     : in    std_logic;
        CLK         : in    std_logic;
        -- Control --
        ACC_WR      : in    std_logic;
        ACC_RD      : out   std_logic;
        FIFO_EMPTY  : out   std_logic;
        FIFO_FULL   : out   std_logic;
        ACC_WDATA   : in    std_logic_vector(7 downto 0);
        ACC_RDATA   : out   std_logic_vector(7 downto 0);
        -- I2C Interface --
        SCL_IN      : in    std_logic;
        SDA_IN      : in    std_logic;
        SDA_OUT     : out   std_logic
    );
end I2C_TARGET_IF;

architecture RTL of I2C_TARGET_IF is

signal sda_shift    : std_logic_vector(7 downto 0);
signal scl_shift    : std_logic_vector(7 downto 0);
signal bit_count    : std_logic_vector(3 downto 0);
signal cycle_count  : std_logic_vector(2 downto 0);
signal i2c_tx_en    : std_logic;
signal i2c_tx_data  : std_logic_vector(7 downto 0);
signal i2c_sda_in   : std_logic;
signal i2c_rx_busy  : std_logic;
signal i2c_rx_data  : std_logic_vector(7 downto 0);

begin
-- ============================================================================
-- I2C SCL Shift Register
-- ============================================================================
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        scl_shift <= (others => '0');
    elsif (CLK'event and CLK = '1') then
        scl_shift <= scl_shift(6 downto 0) & SCL_IN;
    end if;
end process;


-- ============================================================================
-- I2C SDA Shift Register
-- ============================================================================
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        sda_shift <= (others => '0');
    elsif (CLK'event and CLK = '1') then
        sda_shift <= sda_shift(6 downto 0) & SDA_IN;
    end if;
end process;


-- ============================================================================
-- I2C RX Busy
-- ============================================================================
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        i2c_rx_busy <= '0';
    elsif (CLK'event and CLK = '1') then
        if (i2c_rx_busy = '0') then
            if (scl_shift = X"FF" and sda_shift = X"F0") then
                i2c_rx_busy <= '1';
            elsif (cycle_count = 1 and bit_count = 0) then
                i2c_rx_busy <= '1';
            end if;
        else
            if (bit_count = 8) then
                i2c_rx_busy <= '0';
            end if;
        end if;
    end if;
end process;


-- ============================================================================
-- I2C data bit counter
-- ============================================================================
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        bit_count <= (others => '0');
    elsif (CLK'event and CLK = '1') then
        if ((i2c_rx_busy = '1' or i2c_tx_en = '1') and scl_shift = X"F0") then
            if (bit_count < 9) then
                bit_count <= bit_count + 1;
            else
                bit_count <= (others => '0');
            end if;
        end if;
    end if;
end process;


-- ============================================================================
-- I2C cycle counter
-- ============================================================================
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        cycle_count <= (others => '0');
    elsif (CLK'event and CLK = '1') then
        if (i2c_rx_busy = '1') then
            if (bit_count = 9 and scl_shift = X"F0") then
                if (cycle_count = 0 and i2c_rx_data(7) = '1') then
                    cycle_count <= "010";
                elsif (cycle_count < 2) then
                    cycle_count <= "001";
                end if;
            end if;
        else
            cycle_count <= (others => '0');
        end if;
    end if;
end process;


-- ============================================================================
-- I2C RX Data
-- ============================================================================
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        i2c_rx_data <= (others => '0');
    elsif (CLK'event and CLK = '1') then
        if (i2c_rx_busy = '1' and scl_shift = X"0F") then
            i2c_rx_data <= i2c_rx_data(6 downto 0) & sda_shift(3);
        end if;
    end if;
end process;


-- ============================================================================
-- I2C TX Data
-- ============================================================================
process (CLK, RESET_n) begin
    if (RESET_n = '0') then
        i2c_tx_data <= (others => '1');
    elsif (CLK'event and CLK = '1') then
        if (cycle_count = 0 and bit_count = 9 and i2c_rx_data(7) = '1') then
            i2c_tx_data <= X"A5";
        elsif (cycle_count = 2 and scl_shift = X"F0") then
            i2c_tx_data <= i2c_tx_data(6 downto 0) & '1';
        else
            i2c_tx_data <= (others => '0');
        end if;
    end if;
end process;

i2c_tx_en <= '1' when (bit_count = 8 and cycle_count = 0) else
             '1' when (bit_count = 8 and cycle_count = 1) else
             '1' when (bit_count = 8 and cycle_count = 2) else '0';

SDA_OUT <= i2c_tx_data(7) when (i2c_tx_en = '1') else '1';

end architecture RTL;