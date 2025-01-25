# GPIO (no-std)

#### Initialize the ESP & Gain Access to Peripherals

Before utilizing any device peripherals, it's essential to configure the ESP device itself. This involves setting up the device clocks and gaining access to peripheral instances using the singleton pattern, which ensures that only one instance of each peripheral is accessed throughout the application. The `esp-hal` crate facilitates this initialization with a streamlined approach.

```rust
let device_peripherals = esp_hal::init(esp_hal::Config::default());
```

The `init` function takes an `esp_hal::Config` struct as an argument and returns instances of the peripherals and system clocks. Using the default configuration simplifies the setup process by applying standard settings.

```rust
pub struct Config {
    pub cpu_clock: CpuClock,
    pub watchdog: WatchdogConfig,
}
```

This configuration struct allows for customization of system parameters such as CPU clock speed and watchdog settings, although the default values are typically sufficient for basic applications.

#### Create an IO Driver

To control GPIO pins, an IO driver must be instantiated. The `esp_hal::gpio` module provides the `Io` struct, which serves as the driver for managing individual IO pins.

```rust
let io = Io::new(peripherals.GPIO, peripherals.IO_MUX);
```

This code creates a new IO driver instance by passing the GPIO and IO_MUX peripherals obtained during initialization. The IO driver provides access to the individual GPIO pins for further configuration.

#### Configure Pin Direction

After establishing the IO driver, each GPIO pin must be configured as either an input or an output. This configuration determines how the pin will interact with external components.

##### 1. Input Configuration

Configuring a pin as an input allows the microcontroller to read its state. This is achieved using the `Input` struct, which requires specifying the pin and its pull configuration.

```rust
pub fn new(pin: impl Peripheral<P = P> + 'd, pull: Pull) -> Self
```

```rust
let some_input_pin = Input::new(io.pins.gpio3, Pull::Up);
```

In this example, GPIO3 is configured as an input with a pull-up resistor, ensuring that the pin reads a high logic level when inactive.

##### 2. Output Configuration

Configuring a pin as an output enables the microcontroller to control its state, setting it to either high or low.

```rust
pub fn new(pin: impl Peripheral<P = P> + 'd, initial_output: Level) -> Self
```

```rust
let some_output_pin = Output::new(io.pins.gpio3, Level::Low);
```

Here, GPIO3 is set as an output with an initial low level. The push-pull configuration allows the pin to actively drive the signal both high and low.

#### (Output Pins Only): Configure Drive Strength

While optional, configuring the drive strength of output pins can be necessary for applications requiring higher current levels. This is done using the `set_drive_strength` method, which selects the desired drive strength from the available options.

```rust
// Configure a pin with a 5mA Drive
some_pin.set_drive_strength(DriveStrength::I5mA);
// Configure a pin with a 10mA Drive
some_pin.set_drive_strength(DriveStrength::I10mA);
// Configure a pin with a 20mA Drive
some_pin.set_drive_strength(DriveStrength::I20mA);
// Configure a pin with a 40mA Drive
some_pin.set_drive_strength(DriveStrength::I40mA);
```

These configurations adjust the current-driving capability of the GPIO pin, allowing it to handle different levels of electrical load as required by the application.

### Interacting with GPIO

Once the GPIO pins are configured, they can be interacted with through various methods depending on their direction (input or output).

#### Writing/Controlling Output

Output pins can be controlled by setting their state to high or low using the `set_high` and `set_low` methods.

```rust
// Set pin output to low
some_pin.set_low();
// Set pin output to high
some_pin.set_high();
```

These methods allow the microcontroller to manipulate the voltage level on the output pin, enabling control over connected devices such as LEDs or relays.

#### Reading Input by Polling

Input pins can be read by continuously polling their state using the `is_high` and `is_low` methods within a loop.

```rust
loop {
    // Check if input pin is low
    if some_pin.is_low() {
        println!("Input is low!");
    }
    // Check if input pin is high
    if some_pin.is_high() {
        println!("Input is high!");
    }
}
```

This approach involves repeatedly checking the pin's state, which can be resource-intensive but is straightforward to implement.

#### Reading Input by Interrupts

Interrupts provide a more efficient way to handle input changes by triggering an Interrupt Service Routine (ISR) when specific events occur, such as a button press.

```rust
#![no_std]
#![no_main]

use core::cell::{Cell, RefCell};
use critical_section::Mutex;
use esp_backtrace as _;
use esp_hal::{
    gpio::{Event, Input, Pull, Io},
    prelude::*,
};
use esp_println::println;

static G_PIN: Mutex<RefCell<Option<Input>>> = Mutex::new(RefCell::new(None));

// ISR Definition
#[handler]
fn gpio() {
    // Start a Critical Section
    critical_section::with(|cs| {
        // Obtain access to global pin and clear interrupt pending flag
        G_PIN.borrow_ref_mut(cs).as_mut().unwrap().clear_interrupt();
    });
}

#[entry]
fn main() -> ! {
    // Take Peripherals & Configure Device
    let peripherals = esp_hal::init(esp_hal::Config::default());
    // Create IO Driver
    let io = Io::new(peripherals.GPIO, peripherals.IO_MUX);

    // Interrupt Configuration
    // Register interrupt handler
    io.set_interrupt_handler(gpio);
    // Configure pin direction
    let some_pin = Input::new(io.pins.gpio0, Pull::Up);
    // Configure input to trigger an interrupt on the falling edge 
    // and start listening to events
    some_pin.listen(Event::FallingEdge);
    // Now that pin is configured, move the pin to the global context
    critical_section::with(|cs| G_PIN.borrow_ref_mut(cs).replace(some_pin));

    // Following Application Code
    loop {}
}
```

In this example:

1. Global Variable Setup: A global `G_PIN` variable is defined using a `Mutex` and `RefCell` to safely share the GPIO input pin between the main thread and the ISR.
2. ISR Definition: The `gpio` function is marked with the `#[handler]` attribute and serves as the ISR. It clears the interrupt flag to allow future interrupts.
3. Main Function:
    - Initialization: Peripherals are initialized, and an IO driver is created.
    - Interrupt Handler Registration: The ISR is registered to handle GPIO events.
    - Pin Configuration: GPIO0 is set as an input with a pull-up resistor and configured to trigger an interrupt on a falling edge.
    - Global Context Assignment: The configured input pin is moved to the global context within a critical section to ensure thread-safe access.

    








# ADCs (no-std)

#### Initialize the ESP & Gain Access to Peripherals

Before utilizing any device peripherals, the ESP device must be configured, primarily by setting up the device clocks and gaining access to peripheral instances. The singleton pattern is employed to ensure that only one instance of each peripheral is accessed throughout the application, enhancing safety and resource management.

```rust
let device_peripherals = esp_hal::init(esp_hal::Config::default());
```

The `init` function initializes the device with default configuration values, returning instances of peripherals and system clocks. The `esp_hal::Config` struct allows customization of system parameters such as CPU clock speed and watchdog settings, though the default values are typically sufficient for basic applications.

```rust
pub struct Config {
    pub cpu_clock: CpuClock,
    pub watchdog: WatchdogConfig,
}
```

This configuration struct enables developers to tailor the system's behavior by adjusting clock speeds and watchdog parameters as needed.

#### Create an IO Driver

With access to peripherals established, the next step is to create an IO driver, which provides control over individual IO pins. The `esp_hal::gpio` module offers the `Io` struct for this purpose.

```rust
let io = Io::new(peripherals.GPIO, peripherals.IO_MUX);
```

This code initializes the IO driver by passing the GPIO and IO_MUX peripherals obtained during initialization. The IO driver facilitates further configuration and management of specific GPIO pins.

#### Configure Analog Pin and Channel

Not all pins on a microcontroller support analog functions. Depending on the chosen pin, the corresponding ADC instance must be configured. For example, using GPIO4 requires configuring ADC1. Multiple pins can be sampled by the same ADC instance through an internal multiplexer.

After selecting the appropriate pin, the ADC channel configuration is created by specifying the pin and attenuation settings. Attenuation reduces the amplitude of the input signal to fit within the ADC's reference voltage range.

```rust
pub enum Attenuation {
    Attenuation0dB = 0,
    Attenuation2p5dB = 1,
    Attenuation6dB = 2,
    Attenuation11dB = 3,
}
```

```rust
// Create instance for ADC configuration parameters
let mut adc_config = AdcConfig::new();
// Enable a pin with attenuation
let mut adc_pin = adc_config.enable_pin(
    pin_instance,
    Attenuation::Attenuation11dB,
);
```

In this example, the ADC channel is configured with an attenuation of 11 dB for a specific pin. Attenuation allows the ADC to handle higher input voltages by scaling them down, ensuring accurate measurements within the ADC's reference voltage range.

#### Create an ADC Driver

With the ADC channel configured, an ADC driver can be created to manage the ADC instance and perform measurements. The `esp_hal::analog::adc::Adc` type provides the necessary abstraction for this purpose.

```rust
// Create ADC Driver for ADC1
let mut adc1 = Adc::new(peripherals.ADC1, adc_config);
```

This code initializes an ADC driver for ADC1, associating it with the previously configured ADC channel. The ADC driver enables the application to perform analog measurements through the configured ADC instance.

### Interacting with ADCs

Once configured, ADCs can be interacted with to perform measurements. This involves reading analog input values either in a blocking or non-blocking manner.

#### Blocking Read of Input

A blocking read involves initiating a one-shot measurement and waiting until the result is available. This ensures that the application receives the measurement before proceeding, albeit at the cost of halting other operations during the wait.

```rust
let adc_reading: u16 = adc1.read_oneshot(&mut analog_pin).unwrap();
```

While labeled as non-blocking, the `read_oneshot` method returns a `WouldBlock` error if the ADC is not ready, indicating that the operation cannot be completed immediately. To implement a true blocking approach, the `block!` macro from the `nb` crate can be used to wait until the measurement is ready.

```rust
let adc_reading: u16 = nb::block!(adc1.read_oneshot(&mut pin)).unwrap();
```

The `block!` macro ensures that the code waits until the ADC reading is available before proceeding, providing a straightforward way to obtain accurate measurements without handling errors manually.











# ProgrammingTimers & Counters (no-std)

Configuring timers on ESP devices using Rust involves a structured process that ensures precise time-based operations essential for various embedded applications. This configuration leverages the `esp-hal` crate, which provides abstractions for managing timer peripherals within the ESP-IDF framework. The setup process is divided into several key steps, each building upon the previous to establish a reliable timer mechanism.

#### Initialize the ESP & Gain Access to Peripherals

The first step mirrors the initialization process outlined in previous sections. It involves configuring the ESP device and gaining access to its peripherals using the singleton pattern, which ensures that only one instance of each peripheral is accessed throughout the application. This is achieved with the `esp_hal::init` function, which initializes the device with default configurations.

```rust
let device_peripherals = esp_hal::init(esp_hal::Config::default());
```

The `init` function accepts an `esp_hal::Config` struct and returns instances of the peripherals and system clocks, preparing the device for subsequent configurations.

#### Instantiate a Timer Group & Obtain Timer Handle

Once peripherals are initialized, the next step is to create a timer group and obtain a handle for a specific timer within that group. Timer groups allow for the organization and management of multiple timers, facilitating coordinated timing operations.

```rust
let timer_group0 = TimerGroup::new(peripherals.TIMG0);
```

```rust
// Instantiate Timer0 in Timer Group 0
let mut timer0 = timer_group0.timer0;
```

By instantiating `timer_group0` and obtaining `timer0`, developers can manage and control Timer 0 within Timer Group 0, setting the foundation for precise timing operations.

#### Configure Analog Pin and Channel

Configuring the timer involves setting up the timer's parameters, such as the start value, compare value, and enabling features like auto-reload. This ensures that the timer operates according to the desired specifications, whether it’s for counting, generating interrupts, or triggering alarms.

```rust
// Start the timer
fn start(&self)

// Stop the timer
fn stop(&self)

// Reset the timer
fn reset(&self)

// Enable auto-reload of load value
fn enable_auto_reload(&self, auto_reload: bool)

// Load a compare value to the timer
fn load_value(&self, value: MicrosDurationU64) -> Result<(), Error>
```

```rust
// Set Start/Reset Count Value to Zero
timer0.reset();
// Enable Timer to Start Counting
timer0.start();
```

In this example, `timer0` is reset to zero and then started, initiating the counting process. These methods allow for precise control over the timer’s behavior, enabling functionalities such as periodic interrupts or timed events.

#### Create an ADC Driver

After configuring the timer, an ADC driver can be created to manage analog-to-digital conversions. This step involves associating the timer with the ADC instance, facilitating synchronized analog measurements based on timer events.

```rust
// Create a Global Variable for timer to pass between threads.
static G_TIMER: Mutex<
    RefCell<
        Option<Timer<Timer0<TIMG0>, esp_hal::Blocking>>,
    >,
> = Mutex::new(RefCell::new(None));

// ISR Definition
#[handler]
fn tg0_t0_level() {
    // Start a Critical Section
    critical_section::with(|cs| {
        // Clear Timer Interrupt Pending Flag
        G_TIMER
            .borrow_ref_mut(cs)
            .as_mut()
            .unwrap()
            .clear_interrupt();
        // Re-activate Timer Alarm For Interrupts to Occur again
        G_TIMER
            .borrow_ref_mut(cs)
            .as_mut()
            .unwrap()
            .set_alarm_active(true);
    });
    // Any other ISR Code
}

#[entry]
fn main() -> ! {
    // Take Peripherals
    let peripherals = esp_hal::init(esp_hal::Config::default());

    // Instantiate TimerGroup0
    let timer_group0 = TimerGroup::new(peripherals.TIMG0);

    // Instantiate Timer0 in Timer Group0
    let timer0 = timer_group0.timer0;

    // Interrupt Configuration
    // Configure timer to trigger an interrupt every second
    // Load count equivalent to 1 second
    timer0
        .load_value(MicrosDurationU64::micros(1_000_000))
        .unwrap();
    // Enable Alarm to generate interrupts
    timer0.set_alarm_active(true);
    // Activate counter
    timer0.set_counter_active(true);
    // Attach Interrupt and Start listening for timer events
    timer0.set_interrupt_handler(tg0_t0_level);

    // Following Application Code
    timer0.listen();
    // Move the timer to the global context
    critical_section::with(|cs| {
        G_TIMER.borrow_ref_mut(cs).replace(timer0)
    });
    loop {}
}
```

In this comprehensive example:

1. Global Variable Setup: A global `G_TIMER` variable is defined using a `Mutex` and `RefCell` to safely share the timer instance between the main thread and the Interrupt Service Routine (ISR).
2. ISR Definition: The `tg0_t0_level` function is marked with the `#[handler]` attribute and serves as the ISR. It clears the interrupt flag and re-activates the timer alarm to allow for subsequent interrupts.
3. Main Function:
    - Initialization: Peripherals are initialized, and a timer group is instantiated.
    - Timer Configuration: `timer0` is configured to trigger an interrupt every second by loading a count value equivalent to one second (`1_000_000` microseconds) and enabling the alarm.
    - Interrupt Handler Registration: The ISR is attached to `timer0` to handle timer events.
    - Global Context Assignment: The configured timer is moved to the global context within a critical section to ensure thread-safe access.

#### Reading Timers/Counters by Polling

Timers can be read by continuously polling their current value. This method involves checking the timer’s count at regular intervals to determine the elapsed time or to trigger specific actions based on the timer’s state.

```rust
// Activate Counter to Start Counting
timer0.start();

loop {
    // Reset Timer Count (to count from 0)
    timer0.reset();

    // Perform Some Operations

    // Determine Duration
    let dur = some_timer.now().duration_since_epoch().to_secs();
    // Print Timer Elapsed Time (from 0)
    println!("Elapsed Timer Duration in Seconds is {}", dur);
}
```

In this example, `timer0` is started and then continuously reset within a loop. The elapsed time since the epoch is calculated and printed, providing real-time feedback on the timer’s state. This polling approach ensures that the application can monitor the timer's progress and react accordingly.










# PWM (no-std)

#### Initialize the ESP & Gain Access to Peripherals

The initial step involves configuring the ESP device and gaining access to its peripherals. This is achieved using the `esp_hal::init` function, which sets up the device clocks and initializes peripheral instances using the singleton pattern. This ensures that only one instance of each peripheral is accessed throughout the application, promoting safe and efficient hardware resource management.

```rust
let device_peripherals = esp_hal::init(esp_hal::Config::default());
```

The `init` function takes an `esp_hal::Config` struct as an argument and returns instances of the peripherals and system clocks. Using the default configuration simplifies the setup process by applying standard settings.

#### Create an IO Driver

With peripherals initialized, the next step is to create an IO driver, which provides control over individual IO pins. The `esp_hal::gpio` module offers the `Io` struct for this purpose.

```rust
let io = Io::new(peripherals.GPIO, peripherals.IO_MUX);
```

This code initializes the IO driver by passing the GPIO and IO_MUX peripherals obtained during initialization. The IO driver facilitates further configuration and management of specific GPIO pins.

#### Configure the PWM Pin into Output

Before using a pin for PWM output, it must be configured as a push-pull output. This configuration allows the microcontroller to actively drive the pin high or low, enabling precise control over connected devices.

```rust
let some_output_pin = Output::new(io.pins.gpio3, Level::Low);
```

In this example, GPIO3 is set as an output with an initial low level. The push-pull configuration ensures that the pin can actively drive both high and low states, which is essential for generating PWM signals.

#### Create an LEDC Peripheral Driver

The LED Controller (LEDC) peripheral manages PWM signal generation. Creating an LEDC driver involves instantiating the `Ledc` struct and setting the global clock source.

```rust
pub fn new(
    _instance: impl Peripheral<P = LEDC> + 'd
) -> Self
```

```rust
let mut ledc = Ledc::new(peripherals.LEDC);
```

```rust
ledc.set_global_slow_clock(LSGlobalClkSource::APBClk);
```

This code initializes the LEDC driver with the LEDC peripheral and sets the global slow clock source to `APBClk`, which is necessary for timing accuracy in PWM signal generation.

#### Configure the LEDC Timer

Timers are integral to PWM signal generation, determining the frequency and resolution of the PWM signal. Configuring a timer involves associating it with the LEDC instance and setting its parameters such as duty resolution and frequency.

```rust
let ledctimer = ledc.get_timer::<LowSpeed>(ledc::timer::Number::Timer0);
```

```rust
ledctimer
    .configure(timer::config::Config {
        duty: timer::config::Duty::Duty12Bit,
        clock_source: timer::LSClockSource::APBClk,
        frequency: 4u32.kHz(),
    })
    .unwrap();
```

In this example, Timer0 is configured with a 12-bit duty resolution and a frequency of 4 kHz. The `configure` method sets these parameters, ensuring that the PWM signal operates at the desired specifications.

#### Configure a PWM Channel Instance

After configuring the timer, a PWM channel must be set up to generate the PWM signal on a specific pin. This involves associating the output pin with the PWM channel, linking it to the configured timer, and setting the duty cycle.

```rust
let mut channel =
    ledc.get_channel(channel::Number::Channel0, some_output_pin);
```

```rust
pub struct Config<'a, S>
where
    S: TimerSpeed,
{
    pub timer: &'a dyn TimerIFace<S>,
    pub duty_pct: u8,
    pub pin_config: PinConfig,
}
```

```rust
let mut channel0 = ledc.get_channel(channel::Number::Channel0, led);
channel0
    .configure(channel::config::Config {
        timer: &ledctimer,
        duty_pct: 10,
        pin_config: channel::config::PinConfig::PushPull,
    })
    .unwrap();
```

This configuration associates Channel0 with the previously configured Timer0 and sets the duty cycle to 10%. The `PinConfig::PushPull` ensures that the pin can actively drive the PWM signal.

### Interacting with PWM

Once PWM is configured, it can be controlled and monitored through various methods provided by the LEDC driver.

#### Controlling the LEDC PWM Peripheral

PWM signals are primarily controlled by adjusting the duty cycle, which determines the proportion of time the signal stays high versus low within each cycle. This is managed using the `set_duty` method.

```rust
// Set the Desired Duty Cycle
fn set_duty(&self, duty_pct: u8) -> Result<(), Error>
```

This method allows the application to dynamically adjust the duty cycle, enabling effects such as LED fading by smoothly transitioning between different brightness levels.

#### Reading from the LEDC PWM Peripheral

While PWM generation typically does not require reading from the peripheral, certain applications may benefit from monitoring the current state. The `max_duty_cycle` method can be used to retrieve the maximum duty cycle value supported by the configuration.




















# Serial Communication (no-std)

#### Initialize the ESP & Gain Access to Peripherals

Before utilizing any device peripherals, it's crucial to configure the ESP device itself. This involves setting up the device clocks and gaining access to peripheral instances using the singleton pattern. The `esp-hal` crate provides a streamlined method for initializing the device with default configurations.

```rust
let device_peripherals = esp_hal::init(esp_hal::Config::default());
```

The `init` function takes an `esp_hal::Config` struct as an argument and returns instances of the peripherals and system clocks. Using the default configuration simplifies the setup process by applying standard settings, ensuring that the device is ready for peripheral configuration.

```rust
pub struct Config {
    pub cpu_clock: CpuClock,
    pub watchdog: WatchdogConfig,
}
```

The `Config` struct allows customization of system parameters such as CPU clock speed and watchdog settings. However, for basic applications, the default values are typically sufficient, as demonstrated in the initialization step.

#### Create an IO Driver

With peripherals initialized, the next step is to create an IO driver. The IO driver provides control over individual IO pins, enabling their configuration for various functions, including UART communication.

```rust
let io = Io::new(peripherals.GPIO, peripherals.IO_MUX);
```

This code initializes the IO driver by passing the GPIO and IO_MUX peripherals obtained during initialization. The IO driver facilitates further configuration and management of specific GPIO pins required for UART operations.

#### Instantiate UART Pins

Before creating a UART instance, the pins designated for UART communication must be instantiated. Typically, the transmit (TX) pin is configured as an output, and the receive (RX) pin is configured as an input. This configuration ensures proper data transmission and reception.

```rust
// Configure GPIO21 as UART TX (Output)
let uart_tx = Output::new(io.pins.gpio21, Level::Low);

// Configure GPIO20 as UART RX (Input with Pull-Up)
let uart_rx = Input::new(io.pins.gpio20, Pull::Up);
```

In this example:
- GPIO21 is configured as an output pin for transmitting data.
- GPIO20 is configured as an input pin with a pull-up resistor for receiving data.

#### Configure a UART Instance

Configuring UART involves creating a UART instance with specific settings such as baud rate, data bits, parity, stop bits, and clock source. The `esp_hal::uart::Uart` abstraction provides methods to instantiate and configure UART peripherals effectively.

```rust
pub fn new_with_config<TX: OutputPin, RX: InputPin>(
    uart: impl Peripheral<P = T> + 'd,
    config: Config,
    tx: impl Peripheral<P = TX> + 'd,
    rx: impl Peripheral<P = RX> + 'd,
) -> Result<Self, Error>
```

```rust
pub struct Config {
    pub baudrate: u32,
    pub data_bits: DataBits,
    pub parity: Parity,
    pub stop_bits: StopBits,
    pub clock_source: ClockSource,
    pub rx_fifo_full_threshold: u16,
    pub rx_timeout: Option<u8>,
}
```

```rust
// Create a UART Configuration
let uart_config = Config {
    baudrate: 115200,
    data_bits: DataBits::DataBits8,
    parity: Parity::ParityNone,
    stop_bits: StopBits::STOP1,
    clock_source: ClockSource::Apb,
    ..Default::default()
};
```

```rust
let mut log = Uart::new_with_config(
    peripherals.UART0,
    uart_config,
    io.pins.gpio21,
    io.pins.gpio20,
)
.unwrap();
```

In this example:
1. UART Configuration: An instance of `Config` is created with the following settings:
    - Baud Rate: 115200
    - Data Bits: 8
    - Parity: None
    - Stop Bits: 1
    - Clock Source: APB Clock
2. UART Instantiation: A new UART instance (`log`) is created using the `UART0` peripheral, the defined configuration, and the instantiated TX (`gpio21`) and RX (`gpio20`) pins. The `unwrap()` method is used to handle any potential errors during instantiation, assuming successful configuration.

Note: `UART0` is typically used for logging and firmware communication on ESP32-C3 development boards. For UART operations intended for other purposes, it's advisable to consult the device's reference manual to ensure correct peripheral usage and pin assignments.

#### Interacting with UART

Once the UART instance is configured, it can be used to send and receive data. The `Uart` type offers several methods to facilitate standard write and read operations.

##### Writing to the UART Peripheral

Sending data over UART is accomplished through write operations. The `write_bytes` method allows sending a slice of bytes over the UART channel.

```rust
pub fn write_bytes(&mut self, data: &[u8]) -> Result<usize, Error>
```

```rust
some_uart_instance.write_bytes(&[25_u8]).unwrap();
```

In this example, a single byte with the value `25` is sent over the UART channel. The `unwrap()` method ensures that the operation succeeds, and any errors during the write process will cause a panic. For robust applications, consider handling errors gracefully instead of using `unwrap()`.

##### Blocking Read from the UART Peripheral

Receiving data over UART involves read operations. The blocking read approach waits until data is available before proceeding, ensuring that the application receives the intended data.

```rust
fn read(&mut self, buf: &mut [u8]) -> Result<usize, Self::Error>
```

```rust
let mut buf = [0_u8; 1];
some_uart_instance.read(&mut buf).unwrap();
```

In this example:
1. Buffer Initialization: A mutable buffer `buf` is created to store the received byte.
2. Read Operation: The `read` method is called on the UART instance, attempting to read one byte into the buffer. The `unwrap()` method is used to handle any potential errors, assuming successful data reception.

Note: The blocking read approach may halt the execution of other tasks until data is received. For applications requiring concurrent operations, consider implementing non-blocking reads or utilizing asynchronous programming techniques.

### Configuring I2C on ESP Devices

Configuring the Inter-Integrated Circuit (I2C) interface on ESP devices using Rust involves a systematic process that ensures reliable serial communication with various I2C peripherals. I2C is widely used for connecting low-speed peripherals like sensors, displays, and EEPROMs to microcontrollers. This guide outlines the necessary steps to initialize the ESP device, set up the IO driver, configure I2C pins, instantiate and configure an I2C instance, and interact with the I2C peripheral for data transmission and reception.

#### Initialize the ESP & Gain Access to Peripherals

The initial step involves configuring the ESP device and gaining access to its peripherals. This is achieved using the `esp_hal::init` function, which sets up the device clocks and initializes peripheral instances using the singleton pattern. This ensures that only one instance of each peripheral is accessed throughout the application, promoting safe and efficient hardware resource management.

```rust
let device_peripherals = esp_hal::init(esp_hal::Config::default());
```

The `init` function takes an `esp_hal::Config` struct as an argument and returns instances of the peripherals and system clocks. Using the default configuration simplifies the setup process by applying standard settings, ensuring that the device is ready for peripheral configuration.

#### Create an IO Driver

With peripherals initialized, the next step is to create an IO driver. The IO driver provides control over individual IO pins, enabling their configuration for various functions, including I2C communication.

```rust
let io = Io::new(peripherals.GPIO, peripherals.IO_MUX);
```

This code initializes the IO driver by passing the GPIO and IO_MUX peripherals obtained during initialization. The IO driver facilitates further configuration and management of specific GPIO pins required for I2C operations.

#### Create and Configure an I2C Instance

Configuring I2C involves creating an I2C instance with specific settings such as the operating frequency and associating it with designated SDA (Serial Data) and SCL (Serial Clock) pins. The I2c abstraction provides methods to instantiate and configure I2C peripherals effectively.

```rust
pub fn new<SDA: OutputPin + InputPin, SCL: OutputPin + InputPin>(
    i2c: impl Peripheral<P = T> + 'd,
    sda: impl Peripheral<P = SDA> + 'd,
    scl: impl Peripheral<P = SCL> + 'd,
    frequency: HertzU32,
) -> Self
```

```rust
let i2c = I2c::new(
    peripherals.I2C0,
    io.pins.gpio1,
    io.pins.gpio2,
    100u32.kHz(),
);
```

In this example:
1. I2C Peripheral Instance: `peripherals.I2C0` refers to the I2C0 peripheral instance obtained during initialization.
2. SDA and SCL Pins: `io.pins.gpio1` and `io.pins.gpio2` are instantiated as bidirectional pins for SDA and SCL respectively.
3. Frequency: The I2C operation frequency is set to 100 kHz, which is a standard speed for I2C communication.

#### Instantiate UART Pins

Before creating a UART instance, the pins designated for UART communication must be instantiated. Typically, the transmit (TX) pin is configured as an output, and the receive (RX) pin is configured as an input. This configuration ensures proper data transmission and reception.

```rust
// Configure GPIO21 as UART TX (Output)
let uart_tx = Output::new(io.pins.gpio21, Level::Low);

// Configure GPIO20 as UART RX (Input with Pull-Up)
let uart_rx = Input::new(io.pins.gpio20, Pull::Up);
```

In this example:
- GPIO21 is configured as an output pin for transmitting data.
- GPIO20 is configured as an input pin with a pull-up resistor for receiving data.

#### Configure an I2C Instance

Configuring I2C involves creating an I2C instance with specific settings such as the operating frequency and associating it with designated SDA (Serial Data) and SCL (Serial Clock) pins.

```rust
pub fn new<SDA: OutputPin + InputPin, SCL: OutputPin + InputPin>(
    i2c: impl Peripheral<P = T> + 'd,
    sda: impl Peripheral<P = SDA> + 'd,
    scl: impl Peripheral<P = SCL> + 'd,
    frequency: HertzU32,
) -> Self
```

```rust
let i2c = I2c::new(
    peripherals.I2C0,
    io.pins.gpio1,
    io.pins.gpio2,
    100u32.kHz(),
);
```

In this example:
1. I2C Peripheral Instance: `peripherals.I2C0` refers to the I2C0 peripheral instance obtained during initialization.
2. SDA and SCL Pins: `io.pins.gpio1` and `io.pins.gpio2` are instantiated as bidirectional pins for SDA and SCL respectively.
3. Frequency: The I2C operation frequency is set to 100 kHz, which is a standard speed for I2C communication.

#### Interacting with I2C

Once the I2C instance is configured, it can be used to send and receive data to and from I2C devices. The `I2c` type implements the `embedded_io::Write` and `embedded_io::Read` traits, facilitating standard write and read operations.

##### Writing to the I2C Peripheral

Sending data over I2C is accomplished through write operations. The `write` method allows sending a slice of bytes to a specific I2C slave address.

```rust
pub fn write(&mut self, addr: u8, bytes: &[u8]) -> Result<(), Error>
```

```rust
some_i2c_instance.write(0x65, &[25]).unwrap();
```

In this example, a single byte with the value `25` is sent to the I2C slave device with the address `0x65`. The `unwrap()` method is used to handle any potential errors during the write process, assuming successful transmission.

##### Reading from the I2C Peripheral

Receiving data over I2C involves read operations. The `read` method allows reading a specified number of bytes from a particular I2C slave address into a buffer.

```rust
pub fn read(&mut self, address: u8, buffer: &mut [u8]) -> Result<(), Error>
```

```rust
let mut buf = [0_u8; 1];
some_i2c_instance.read(0x65, &mut buf).unwrap();
```

In this example:
1. Buffer Initialization: A mutable buffer `buf` is created to store the received byte.
2. Read Operation: The `read` method is called on the I2C instance, attempting to read one byte from the I2C slave device at address `0x65` into the buffer. The `unwrap()` method is used to handle any potential errors, assuming successful data reception.







# The Embassy Framework (no-std)

In a blocking approach, the processor sits idle, busy waiting (continuously polling) for a result. This not only wastes processing power but also prevents other code from executing concurrently. A potential solution to this issue is using interrupts, which can notify the application when an event occurs. However, configuring interrupts can be daunting and increases code verbosity.

#### Introducing Asynchronous Programming

Asynchronous programming offers an elegant alternative and has gained significant popularity in Rust circles. Asynchronous (often abbreviated as "async") programming in Rust allows you to run multiple tasks concurrently while preserving the synchronous, readable nature of regular Rust code. Async programming in Rust involves three main components:

1. Futures: Represent work that may complete in the future.
2. Async/Await Syntax: Handles asynchronous tasks in a non-blocking manner.
3. Runtime: Executes the asynchronous tasks.

Rust’s asynchronous operation is based on futures, which are polled in the background until they signal completion. The `async` keyword transforms a block of code into a future, and the `await` keyword is used to wait for the future to resolve without blocking the entire thread. The `await` keyword also implies deferred execution, allowing the program to handle other tasks while waiting for the future to complete.

Unlike some other languages, Rust does not include a built-in runtime for asynchronous operations. Instead, developers must choose a runtime, such as Tokio, async-std, smol, etc., and include it as a dependency. In embedded Rust development, the Embassy executor serves this purpose.

#### The Embassy Executor

The Embassy executor is part of the Embassy framework, which offers more than just a runtime. Embassy provides an efficient and easy-to-use multitasking environment using Rust’s `async/await` syntax. Additionally, Embassy offers Hardware Abstraction Layers (HALs) for select hardware, providing safe, idiomatic Rust APIs for hardware capabilities. It also includes crates for time management, connectivity, and networking features, among others. Embassy is poised to become a significant tool in embedded development by offering a lightweight runtime that facilitates writing multithreaded, efficient, and safe code without the overhead of a Real-Time Operating System (RTOS).

Notable Embassy Crates:

- embassy-time: Provides timekeeping, delays, and timeout abstractions.
- embassy-net: Offers an async network stack.
- embassy-sync: Supplies synchronization primitives and data structures with async support.
- embassy-usb: Delivers an async USB device stack.
- embassy-executor: Contains async/await executor abstractions.

Asynchronous programming is powerful and has been prevalent in areas like web development. In embedded development, it is relatively new and may take some time for wide-scale adoption. However, Embassy’s stable and efficient abstractions make it a promising candidate for the future of embedded Rust development.

#### Getting Started with Embassy

Getting started with the Embassy framework is straightforward. Technically, you need to:

1. Import the Embassy crates.
2. Initialize the background executor.
3. Use async abstractions.

Condition: The underlying HAL used with Embassy must support async development. This means the HAL should implement or provide access to async functions. ESP devices support the Embassy framework by leveraging community-driven HALs, such as `embedded-hal-async` and `embedded-io-async`, maintained by the embedded Rust workgroup. These HALs establish common behavior among devices, enabling portability across a wider range of hardware platforms.

Note: Currently, no-std Embassy support with ESPs is limited to peripherals supported by the `embedded-hal-async` and `embedded-io-async` crates. Not all peripherals have async abstractions, so consult the documentation for supported peripherals.

Below is a basic template demonstrating the use of Embassy with the `esp-hal`. This template includes two tasks: the main task and an `embassy_task` spawned by main. Key differences from earlier templates include:

1. `main` Function Declared as `async`: Allows deferring execution to the background executor and awaiting futures.
2. Spawner Handle: Passed to `main` to spawn additional tasks.
3. Initialization of the Embassy Executor: Using `embassy::init` with an async timer instance.
4. Spawning Tasks: Using `spawner.spawn` to add tasks to the executor.
5. Delay Creation with `Timer::after`: Creates a future that resolves after a specified duration.

```rust
#![no_std]
#![no_main]

use embassy_executor::Spawner;
use embassy_time::{Duration, Timer};
use esp_backtrace as _;
use esp_hal::{prelude::*, timer::timg::TimerGroup};
use esp_hal_embassy;
use esp_println::println;

#[embassy_executor::task]
async fn embassy_task() {
    loop {
        // Task Loop Code
        println!("Print from an embassy task");
        Timer::after(Duration::from_millis(1_000)).await;
    }
}

#[main]
async fn main(spawner: Spawner) {
    println!("Init!");
    let peripherals = esp_hal::init(esp_hal::Config::default());

    // Initialize Embassy executor
    let timg0 = TimerGroup::new(peripherals.TIMG0);
    esp_hal_embassy::init(timg0.timer0);

    spawner.spawn(embassy_task()).unwrap();

    loop {
        // Main loop code
        println!("Print from the main task");
        Timer::after(Duration::from_millis(5_000)).await;
    }
}
```

```toml
[dependencies]
esp-backtrace = { version = "0.14.1", features = [
    "esp32c3",
    "exception-handler",
    "panic-handler",
    "println",
] }
esp-hal = { version = "0.21.0", features = ["esp32c3"] }
esp-println = { version = "0.12.0", features = ["esp32c3", "log"] }
log = { version = "0.4.20" }
esp-hal-embassy = { version = "0.4.0", features = [
    "esp32c3",
    "integrated-timers",
    "log",
] }
embassy-executor = { version = "0.6.0", features = ["task-arena-size-40960"] }
embassy-futures = "0.1.1"
embassy-sync = "0.6.0"
embassy-time = "0.3.2"
embedded-hal-async = "1.0.0"
embedded-io-async = "0.6.1"
```

Explanation of `Cargo.toml` Dependencies:

- esp-backtrace: Handles backtraces for debugging.
- esp-hal: Provides Hardware Abstraction Layer for ESP devices.
- esp-println: Facilitates printing/logging capabilities.
- log: Logging facade.
- esp-hal-embassy: Integrates Embassy with the ESP HAL.
- embassy-executor: Async executor for Embassy.
- embassy-futures: Future abstractions for Embassy.
- embassy-sync: Synchronization primitives for async tasks.
- embassy-time: Time management utilities for Embassy.
- embedded-hal-async: Async traits for embedded HAL.
- embedded-io-async: Async traits for embedded IO.

#### Synchronization Primitives

In the following sections, we will explore some of Embassy’s synchronization primitives that are particularly useful when sharing data among tasks or threads. These primitives help manage access to shared resources without introducing race conditions, ensuring thread-safe operations in an asynchronous environment.

### Synchronization Primitives

When introducing interrupts earlier, dealing with global variables presented significant challenges. The primary issue stems from ensuring that variables are shared safely among threads to prevent synchronization problems like data races. However, using the Embassy framework, this experience is greatly improved through several synchronization primitives provided by the `embassy-sync` crate.

But with several primitives available, how do we decide which one to use? The answer lies in how you plan to share the data. Specifically, consider whether you want to:

1. Share data among tasks in a blocking manner
2. Require async support for shared data
3. Need the primitive to notify a task when the data it holds changes

The `embassy-sync` crate offers the following primitives to cater to these scenarios:

- Channel: A Multiple Producer Multiple Consumer (MPMC) channel where each message sent is received by a single consumer.
- PubSubChannel: A broadcast (publish-subscribe) channel where each message sent is received by all consumers.
- Signal: Signals the latest value to a single consumer.
- Mutex: Synchronizes state between asynchronous tasks.
- Pipe: A byte stream that implements `embedded-io` traits.

Additionally, there are Waker primitives, which are utilities to signal the executor to poll a Future. These include:

- WakerRegistration: Utility to register and wake a Waker.
- AtomicWaker: A variant of `WakerRegistration` accessible using a non-mut API.
- MultiWakerRegistration: Utility for registering and waking multiple Wakers.

#### Use Cases

The use of different synchronization primitives can be categorized into three main cases:

1. Reading/Writing from/to Multiple Tasks: Sharing simple data among multiple tasks.
2. Reading/Writing Across Async Tasks: Sharing data across asynchronous tasks, requiring safe mutation while awaiting.
3. Wait for Value Change: Scenarios where a receiving task waits for a change in a value.

In the following sections, we will explore the constructs available under each category.

---

#### The `AtomicU32` Type

While `AtomicU32` is not explicitly listed among the Embassy synchronization primitives, it is a valuable tool available in Rust’s `core::sync::atomic` module. It is especially handy when you need to share a simple value among tasks without the overhead of more complex synchronization mechanisms. However, `AtomicU32` works only for types that are `u32` or smaller in size. For larger types, you should use a global blocking `Mutex`.

```rust
#![no_std]
#![no_main]

use core::sync::atomic::{AtomicU32, Ordering};
use embassy_executor::Spawner;
use embassy_time::{Duration, Timer};
use esp_backtrace as _;
use esp_hal::{prelude::*, timer::timg::TimerGroup};
use esp_println::println;

// Shared AtomicU32 variable initialized to 0
static SHARED: AtomicU32 = AtomicU32::new(0);

#[embassy_executor::task]
async fn async_task() {
    loop {
        // Load the current value, increment, and store it back
        let shared_var = SHARED.load(Ordering::Relaxed);
        SHARED.store(shared_var.wrapping_add(1), Ordering::Relaxed);
        
        // Wait for 1 second
        Timer::after(Duration::from_millis(1000)).await;
    }
}

#[main]
async fn main(spawner: Spawner) {
    // Initialize and create handle for device peripherals
    let peripherals = esp_hal::init(esp_hal::Config::default());
    
    // Initialize Embassy executor
    let timg0 = TimerGroup::new(peripherals.TIMG0);
    esp_hal_embassy::init(timg0.timer0);
    
    // Spawn the asynchronous task
    spawner.spawn(async_task()).unwrap();

    loop {
        // Load the current shared value
        let shared = SHARED.load(Ordering::Relaxed);
        
        // Wait for 1 second
        Timer::after(Duration::from_millis(1000)).await;
        
        // Print the shared value
        println!("{}", shared);
    }
}
```

Explanation:

1. Global Variable Setup: A global `SHARED` variable of type `AtomicU32` is defined and initialized to `0`.
2. Asynchronous Task (`async_task`):
    - Continuously increments the `SHARED` variable every second.
    - Uses `load` with `Ordering::Relaxed` to retrieve the current value.
    - Uses `store` with `Ordering::Relaxed` to update the value.
3. Main Function:
    - Initializes peripherals and the Embassy executor.
    - Spawns the `async_task`.
    - In the main loop, it reads and prints the `SHARED` value every second.

*Note: `Ordering::Relaxed` is used here for simplicity, assuming that the exact ordering of operations is not critical. For more complex synchronization requirements, stronger memory ordering guarantees may be necessary.*

---

#### The Blocking `Mutex` Type

For scenarios where you need to share data types larger than `u32` or require more complex synchronization, a blocking `Mutex` is the appropriate choice. The blocking `Mutex` ensures safe access to shared data by allowing only one task to access the data at a time, effectively preventing data races.

```rust
#![no_std]
#![no_main]

use core::cell::RefCell;
use embassy_executor::Spawner;
use embassy_sync::blocking_mutex::raw::CriticalSectionRawMutex;
use embassy_sync::blocking_mutex::Mutex;
use embassy_time::{Duration, Timer};
use esp_backtrace as _;
use esp_hal::{prelude::*, timer::timg::TimerGroup};
use esp_println::println;

// Shared Mutex-protected u32 variable initialized to 0
static SHARED: Mutex<CriticalSectionRawMutex, RefCell<u32>> = Mutex::new(RefCell::new(0));

#[embassy_executor::task]
async fn async_task() {
    loop {
        // Acquire the mutex lock and modify the shared value
        SHARED.lock(|f| {
            let val = f.borrow_mut().wrapping_add(1);
            f.replace(val);
        });
        
        // Wait for 1 second
        Timer::after(Duration::from_millis(1000)).await;
    }
}

#[main]
async fn main(spawner: Spawner) {
    // Initialize and create handle for device peripherals
    let peripherals = esp_hal::init(esp_hal::Config::default());
    
    // Initialize Embassy executor
    let timg0 = TimerGroup::new(peripherals.TIMG0);
    esp_hal_embassy::init(timg0.timer0);
    
    // Spawn the asynchronous task
    spawner.spawn(async_task()).unwrap();

    loop {
        // Wait for 1 second
        Timer::after(Duration::from_millis(1000)).await;
        
        // Acquire the mutex lock and read the shared value
        let shared = SHARED.lock(|f| f.borrow().clone());
        
        // Print the shared value
        println!("{}", shared);
    }
}
```

Explanation:

1. Global Variable Setup: A global `SHARED` variable is defined as a `Mutex` protecting a `RefCell<u32>`, initialized to `0`.
2. Asynchronous Task (`async_task`):
    - Continuously increments the `SHARED` variable every second.
    - Uses the `lock` method to safely access and modify the shared data.
3. Main Function:
    - Initializes peripherals and the Embassy executor.
    - Spawns the `async_task`.
    - In the main loop, it acquires the mutex lock to read the `SHARED` value every second and prints it.

Key Differences from `AtomicU32`:

- Data Type Flexibility: The `Mutex` allows for sharing data types larger than `u32`, providing greater flexibility.
- Locking Mechanism: The `Mutex` ensures that only one task can access the shared data at a time, preventing concurrent modifications and ensuring data integrity.
- No Atomic Operations: Unlike `AtomicU32`, which provides atomic operations, the `Mutex` relies on locking to synchronize access.

*Note: The `CriticalSectionRawMutex` is chosen for this example, but depending on the context and requirements, other mutex types provided by Embassy may be more appropriate.*

#### The `async Mutex` Type

While the blocking `Mutex` ensures safe access to shared data by allowing only one task to hold the lock at a time, it does not hold the lock across `await` points. In contrast, the `async Mutex` provided by the `embassy-sync` crate allows a task to `await` while holding the lock, enabling other tasks to proceed without being blocked indefinitely.

Key Differences:
- Blocking `Mutex`:
    - Does not support holding the lock across `await` points.
    - Suitable for scenarios where tasks do not need to hold the lock while awaiting.
- `async Mutex`:
    - Allows holding the lock across `await` points.
    - Suitable for scenarios where tasks need to hold the lock while performing asynchronous operations.

```rust
#![no_std]
#![no_main]

use embassy_executor::Spawner;
use embassy_sync::mutex::Mutex;
use embassy_time::{Duration, Timer};
use esp_backtrace as _;
use esp_hal::{prelude::*, timer::timg::TimerGroup};
use esp_hal_embassy;
use esp_println::println;

// Shared async Mutex-protected u32 variable initialized to 0
static SHARED: Mutex<embassy_sync::mutex::raw::CriticalSectionRawMutex, u32> 
  = Mutex::new(0);

#[embassy_executor::task]
async fn async_task() {
    loop {
        {
            // Acquire the mutex lock and modify the shared value
            let mut shared = SHARED.lock().await;
            *shared = shared.wrapping_add(1);
            
            // Hold the lock while awaiting (simulated by a delay)
            Timer::after(Duration::from_millis(1000)).await;
        }
        // The lock is automatically released here
        Timer::after(Duration::from_millis(1000)).await;
    }
}

#[main]
async fn main(spawner: Spawner) {
    // Initialize and create handle for device peripherals
    let peripherals = esp_hal::init(esp_hal::Config::default());

    // Initialize Embassy executor
    let timg0 = TimerGroup::new(peripherals.TIMG0);
    esp_hal_embassy::init(timg0.timer0);

    // Spawn the asynchronous task
    spawner.spawn(async_task()).unwrap();

    loop {
        // Wait for 1 second
        Timer::after(Duration::from_millis(1000)).await;
        
        // Acquire the mutex lock and read the shared value
        let shared = SHARED.lock().await;
        
        // Print the shared value
        println!("{}", shared);
    }
}
```

Explanation:

1. Global Variable Setup:
    - A global `SHARED` variable is defined as an `async Mutex` protecting a `u32`, initialized to `0`.

2. Asynchronous Task (`async_task`):
    - Continuously increments the `SHARED` variable every second.
    - Uses the `lock().await` method to safely acquire and hold the mutex lock.
    - The lock is held while awaiting the timer, ensuring that no other task can access `SHARED` during this period.

3. Main Function:
    - Initializes peripherals and the Embassy executor.
    - Spawns the `async_task`.
    - In the main loop, it waits for one second, acquires the mutex lock to read the `SHARED` value, and prints it.

Behavior:
- The `async_task` increments the shared value every second while holding the lock during the delay.
- The main task attempts to read the shared value every second. If the `async_task` is holding the lock (during its `await`), the main task will wait until the lock becomes available.
- This ensures synchronized access to the shared variable without data races.

Important Considerations:
- Lock Scope: The lock is held within a scoped block `{ ... }`, ensuring it is released before the main task attempts to acquire it again.
- Ordering: Unlike atomic types, mutexes ensure exclusive access, making them suitable for more complex data manipulation.

---

#### The `Signal` Type

The `Signal` primitive is ideal for scenarios where a task needs to be notified when a particular value changes. It provides a simple mechanism to buffer or send a new value to another task, effectively signaling that an update has occurred.

Use Case:
- When one task needs to notify another task about a specific event or data change without continuous polling.

```rust
#![no_std]
#![no_main]

use embassy_executor::Spawner;
use embassy_sync::signal::Signal;
use embassy_time::{Duration, Timer};
use esp_backtrace as _;
use esp_hal::{prelude::*, timer::timg::TimerGroup};
use esp_hal_embassy;
use esp_println::println;

// Shared Signal-protected u32 variable
static SHARED: Signal<embassy_sync::mutex::raw::CriticalSectionRawMutex, u32> 
  = Signal::new();

#[embassy_executor::task]
async fn async_task() {
    loop {
        // Signal the value 5
        SHARED.signal(5);
        
        // Wait for 1 second
        Timer::after(Duration::from_millis(1000)).await;
    }
}

#[main]
async fn main(spawner: Spawner) {
    // Initialize and create handle for device peripherals
    let peripherals = esp_hal::init(esp_hal::Config::default());

    // Initialize Embassy executor
    let timg0 = TimerGroup::new(peripherals.TIMG0);
    esp_hal_embassy::init(timg0.timer0);

    // Spawn the asynchronous task
    spawner.spawn(async_task()).unwrap();

    loop {
        // Wait for a signal and retrieve the value
        let val = SHARED.wait().await;
        
        // Print the received value
        println!("{}", val);
    }
}
```

Explanation:

1. Global Variable Setup:
    - A global `SHARED` variable is defined as a `Signal` protecting a `u32`.

2. Asynchronous Task (`async_task`):
    - Continuously sends (signals) the value `5` every second using the `signal` method.

3. Main Function:
    - Initializes peripherals and the Embassy executor.
    - Spawns the `async_task`.
    - In the main loop, it awaits a signal using the `wait().await` method and prints the received value.

Behavior:
- The `async_task` sends a signal with the value `5` every second.
- The main task waits for the signal and, upon receiving it, prints the value.
- This setup eliminates the need for the main task to continuously poll for updates, making the communication more efficient.

Advantages Over `AtomicU32`:
- Event-Driven: `Signal` allows tasks to react to specific events or changes rather than continuously checking for updates.
- Buffering: Signals can buffer values, ensuring that important updates are not missed even if the receiving task is busy.

---

#### The `Channel` Type

The `Channel` primitive expands upon the capabilities of `Signal` by allowing multiple values to be buffered in a queue. It supports multiple producers and multiple consumers, making it suitable for scenarios where multiple tasks need to send and receive messages concurrently.

Use Case:
- When you need to buffer multiple values sent by producers and have them processed by consumers in a first-come, first-served manner.

```rust
#![no_std]
#![no_main]

use embassy_executor::Spawner;
use embassy_sync::channel::Channel;
use embassy_time::{Duration, Timer};
use esp_backtrace as _;
use esp_hal::{prelude::*, timer::timg::TimerGroup};
use esp_hal_embassy;
use esp_println::println;

// Declare a channel with capacity of 2 u32s
static SHARED: Channel<embassy_sync::mutex::raw::CriticalSectionRawMutex, u32, 2> 
  = Channel::new();

#[embassy_executor::task]
async fn async_task_one() {
    loop {
        // Send the value 1
        SHARED.send(1).await;
        
        // Wait for 0.5 seconds
        Timer::after(Duration::from_millis(500)).await;
    }
}

#[embassy_executor::task]
async fn async_task_two() {
    loop {
        // Send the value 2
        SHARED.send(2).await;
        
        // Wait for 1 second
        Timer::after(Duration::from_millis(1000)).await;
    }
}

#[main]
async fn main(spawner: Spawner) {
    // Initialize and create handle for device peripherals
    let peripherals = esp_hal::init(esp_hal::Config::default());

    // Initialize Embassy executor
    let timg0 = TimerGroup::new(peripherals.TIMG0);
    esp_hal_embassy::init(timg0.timer0);

    // Spawn asynchronous tasks
    spawner.spawn(async_task_one()).unwrap();
    spawner.spawn(async_task_two()).unwrap();

    loop {
        // Receive a value from the channel
        let val = SHARED.receive().await;
        
        // Print the received value
        println!("{}", val);
    }
}
```

Explanation:

1. Global Variable Setup:
    - A global `SHARED` channel is defined with a capacity of `2` for `u32` values.

2. Asynchronous Tasks (`async_task_one` and `async_task_two`):
    - `async_task_one` sends the value `1` every 0.5 seconds.
    - `async_task_two` sends the value `2` every 1 second.

3. Main Function:
    - Initializes peripherals and the Embassy executor.
    - Spawns both asynchronous tasks.
    - In the main loop, it awaits messages from the `SHARED` channel and prints them as they are received.

Behavior:
- The channel buffers up to two messages.
- `async_task_one` sends `1` every 0.5 seconds, and async_task_two sends `2` every 1 second.
- The main task receives and prints each value in the order they are sent.
- If the channel is full, producers will wait (`await`) until there is space available.

Important Notes:
- Capacity: The channel's capacity determines how many messages can be buffered before producers are blocked.
- Multiple Producers: Both `async_task_one` and `async_task_two` act as producers, sending messages to the channel.
- Single Consumer: The main task acts as the sole consumer, receiving and processing messages.

---

#### The `PubSubChannel` Type

The `PubSubChannel` is an extension of the `Channel` type that supports a publish-subscribe (pub-sub) communication model. Unlike `Channel`, where each message is consumed by a single consumer, `PubSubChannel` allows multiple subscribers to receive each published message.

Use Case:
- When you need to broadcast messages to multiple consumers, ensuring that each subscriber receives every message.

```rust
#![no_std]
#![no_main]

use embassy_executor::Spawner;
use embassy_sync::pubsub::PubSubChannel;
use embassy_time::{Duration, Timer};
use esp_backtrace as _;
use esp_hal::{prelude::*, timer::timg::TimerGroup};
use esp_hal_embassy;
use esp_println::println;

// Declare a PubSub channel with capacity of 2 messages,
// 2 publishers, and 2 subscribers
static SHARED: PubSubChannel<
    embassy_sync::mutex::raw::CriticalSectionRawMutex,
    u32,
    2, // Capacity
    2, // Number of publishers
    2, // Number of subscribers
> = PubSubChannel::new();

#[embassy_executor::task]
async fn async_task_one() {
    // Obtain a publisher
    let pub1 = SHARED.publisher().unwrap();
    loop {
        // Publish the value 1 immediately
        pub1.publish_immediate(1);
        
        // Wait for 0.5 seconds
        Timer::after(Duration::from_millis(500)).await;
    }
}

#[embassy_executor::task]
async fn async_task_two() {
    // Obtain a publisher
    let pub2 = SHARED.publisher().unwrap();
    loop {
        // Publish the value 2 immediately
        pub2.publish_immediate(2);
        
        // Wait for 1 second
        Timer::after(Duration::from_millis(1000)).await;
    }
}

#[main]
async fn main(spawner: Spawner) {
    // Initialize and create handle for device peripherals
    let peripherals = esp_hal::init(esp_hal::Config::default());

    // Initialize Embassy executor
    let timg0 = TimerGroup::new(peripherals.TIMG0);
    esp_hal_embassy::init(timg0.timer0);

    // Spawn asynchronous tasks
    spawner.spawn(async_task_one()).unwrap();
    spawner.spawn(async_task_two()).unwrap();

    // Obtain a subscriber
    let mut sub = SHARED.subscriber().unwrap();

    loop {
        // Wait for the next message from the subscriber
        let val = sub.next_message_pure().await;
        
        // Print the received value
        println!("{}", val);
    }
}
```

Explanation:

1. Global Variable Setup:
    - A global `SHARED` `PubSubChannel` is defined with a capacity of `2`, supporting `2` publishers and `2` subscribers.

2. Asynchronous Tasks (`async_task_one` and `async_task_two`):
    - Both tasks obtain their own publishers (`pub1` and `pub2`).
    - `async_task_one` publishes the value `1` every 0.5 seconds.
    - `async_task_two` publishes the value `2` every 1 second.

3. Main Function:
    - Initializes peripherals and the Embassy executor.
    - Spawns both asynchronous tasks.
    - Obtains a subscriber (`sub`) to receive messages.
    - In the main loop, it waits for messages from the subscriber and prints them as they are received.

Behavior:
- Each published message is broadcasted to all subscribers.
- In this example, the main task acts as a single subscriber receiving messages from both publishers.
- If multiple subscribers were present, each would receive every message published to the channel.
- If a subscriber misses a message because it was busy or not ready, it will receive an error signaling that occurrence.

Important Considerations:
- Message Delivery: Every message published is delivered to all active subscribers.
- Error Handling: Subscribers may receive errors if they miss messages due to buffer overflows or other issues.
- Capacity Management: The channel's capacity should be chosen based on the expected message rate and subscriber readiness to prevent message loss.


Role of link_patches() in Rust
When developing in Rust, you’re often interacting with ESP-IDF's C/C++ ecosystem through FFI (Foreign Function Interface). The esp_idf_svc::sys::link_patches() function serves as a bridge to ensure that any necessary patches are correctly linked and applied within the Rust application context.
Rust enforces strict safety and initialization rules, which means that any modifications to the system (like applying patches) must be handled meticulously to maintain these guarantees. link_patches() ensures that patches are applied in a manner consistent with Rust's safety expectations.

Ordering::Relaxed is the most permissive memory ordering. When you use relaxed ordering for atomic operations, you are specifying that the operation should be atomic (i.e., indivisible and free from data races) but do not require any synchronization or ordering guarantees with respect to other atomic operations. This means:

Atomicity is ensured: The operation will be performed atomically, preventing data races on that specific atomic variable.
No synchronization or ordering: There are no guarantees about the visibility of this operation to other threads relative to other operations. Other threads might see these operations in a different order, or not see them at all without additional synchronization.




blinky
led-bar-blink
button-press-counter

sample-voltmeter
temperature-sensing (optional)

real-time-timer

led-fading

uart-xor-cipher
l2c-real-time-clock (optional)

connecting-to-wifi
simple-http-client
simple-http-server
synchronizing-system-time

// tworzenie projektu
// przygotowanie środowiska
// debug
// flushing
