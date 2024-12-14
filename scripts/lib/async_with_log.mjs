import chalk from 'chalk';

export async function asyncWithBreathingLog(
  asyncFn, // Async or sync function
  params = {}, // Parameters can be an array or object
  logMessage = 'Processing...' // Log message
) {
  let intensity = 0; // Current brightness level
  let direction = 1; // Breathing effect direction

  // Create a timer to display the "breathing effect"
  const breathingEffect = setInterval(() => {
    const color = chalk.rgb(intensity, intensity, intensity); // Generate grayscale color
    process.stdout.write(`\r${color(`● ${logMessage}`)}`); // Dynamically output log
    intensity += direction * 15;
    if (intensity >= 255 || intensity <= 0) direction *= -1;
  }, 50);

  try {
    // Check and invoke the function (sync or async)
    const result = await (() => {
      if (typeof asyncFn !== 'function') {
        throw new Error('The first argument must be a function.');
      }

      // Determine parameter type
      if (Array.isArray(params)) {
        // If the parameters are an array, spread them
        return Promise.resolve(asyncFn(...params));
      } else if (typeof params === 'object') {
        // If the parameters are an object, pass it directly
        return Promise.resolve(asyncFn(params));
      } else {
        // Throw an error if parameter type is invalid
        throw new Error('Invalid parameters: must be an array or an object.');
      }
    })();

    // Stop the breathing effect
    clearInterval(breathingEffect);
    process.stdout.write('\r'); // Clear the animation line

    // Display success log
    console.log(chalk.green(`✔ ${logMessage}`));
    return result; // Return the result of the function
  } catch (error) {
    // Stop the breathing effect
    clearInterval(breathingEffect);
    process.stdout.write('\r'); // Clear the animation line

    // Display error log
    console.log(chalk.red(`✖ ${logMessage}`));
    throw error; // Re-throw the error for upper-level handling
  }
}

export function simpleError(message, clean = false) {
  if (clean) {
    process.stdout.write('\x1B[1A'); // Move the cursor up one line
    process.stdout.write('\x1B[2K'); // Clear the current line
    process.stdout.write(`\r${chalk.red(`✖ ${message}`)}\n`);
  } else {
    process.stdout.write(`${chalk.red(`✖ ${message}`)}\n`);
  }
}

export function simpleSuccess(message, clean = false) {
  if (clean) {
    process.stdout.write('\x1B[1A'); // Move the cursor up one line
    process.stdout.write('\x1B[2K'); // Clear the current line
    process.stdout.write(`\r${chalk.green(`✔ ${message}`)}\n`);
  } else {
    process.stdout.write(`${chalk.green(`✔ ${message}`)}\n`);
  }
}
