#!/usr/bin/env node
import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';
import createConfig from './sub/create_config.mjs';
import chalk from 'chalk';
import deploy from './sub/deploy.mjs';


const cmd = yargs(hideBin(process.argv));

// sub commands
const create_config = {
  command: 'create_config', // 子命令名称和参数定义
  describe: 'Create new config for deployment', // 命令描述
  builder: (yargs) => {
    yargs
      .option('out', {
        describe: 'The location file to store',
        type: 'string',
        default: 'deploy/config.yml'
      })
      .option('env', {
        describe: "The runtime environment",
        type: "string",
        default: 'dev'
      })
      .option('token_process_name', {
        describe: 'The process name of token process',
        type: 'string',
        default: 'APUS_RC0'
      })
      .option('token_name', {
        describe: 'The name of token',
        type: 'string',
        default: 'Apus Release Candidate 0'
      })
      .option('stats_process_name', {
        describe: "The name of stats process name",
        type: 'string',
        default: 'APUS_STATS_RC0'
      })
      .option('token_ticker', {
        describe: 'The ticker of the token',
        type: 'string',
        default: 'APUS_RC0'
      })
  },
  handler: (argv) => {
    createConfig(argv)
  },
};

const deployCommand = {
  command: 'deploy', // 子命令名称和参数定义
  describe: 'deploy the processes', // 命令描述
  builder: (yargs) => {
    yargs
      .positional('token_process_name', {
        describe: 'The process name of token process',
        type: 'string',
        default: 'APUS_RC0'
      })
      .positional('token_name', {
        describe: 'The name of token',
        type: 'string',
        default: 'Apus Release Candidate 0'
      })
      .positional('token_ticker', {
        describe: 'The ticker of token',
        type: 'string',
        default: 'APUS_RC0'
      })
      .positional('stats_process_name', {
        describe: "The name of stats process name",
        type: 'string',
        default: 'APUS_STATS_RC0'
      })
      .option('config', {
        description: 'config location',
        type: 'string',
        demandOption: false
      })
      .option('env', {
        description: 'production or test',
        type: 'string',
        default: "test"
      })
  },
  handler: (argv) => {
    deploy(argv)
  },
}

// 定义子命令
cmd
  .scriptName('npx helper')
  .command(create_config)
  .command(deployCommand)
  .demandCommand(1, chalk.red('You must provide at least one command.')) // 必须输入命令
  .fail((msg, err, yargs) => {
    if (err) {
      console.error(chalk.red('Error:'), err.message);
    } else {
      console.error(chalk.red('Error:'), msg);
    }
    console.log('\n');
    yargs.showHelp(); // 自动显示帮助信息
    process.exit(1);
  })
  .help() // 显示帮助信息
  .argv;  // 解析参数
