#!/usr/bin/env node
import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';
import createConfig from './sub/create_config.mjs';
import chalk from 'chalk';
import deploy from './sub/deploy.mjs';
import subscribe from './sub/subscribe.mjs';
import { testAllocation } from './sub/test_allocation.mjs';
import generateTestAddresses from './sub/generate_ether_accounts.mjs';
import allowMintReport from './sub/allow_mint_report.mjs';
import sendMessageToToken from './sub/send_message_to_token.mjs';
import monitorProcess from './sub/monitor.mjs';
import { checkAfterDeploy } from './sub/check_after_deploy.mjs';
import mint from './sub/mint.mjs';


const cmd = yargs(hideBin(process.argv));

// sub commands
const create_config = {
  command: 'create_config',
  describe: 'Create new config for deployment',
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
  command: 'deploy',
  describe: 'deploy the processes',
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
      .option('allowMint', {
        description: 'timestamp that the process will start to process with mint reports',
        type: 'number',
        demandOption: true,
      })
  },
  handler: (argv) => {
    deploy(argv)
  },
}

const subscribeCommand = {
  command: "subscribe",
  describe: "subscribe AO mint report with the target key file.",
  builder: (yargs) => {
    yargs
      .option('keyFile', {
        describe: 'The location of key file',
        type: 'string',
        demandOption: true
      })
      .option('reportTo', {
        describe: 'Which address the report is sent to',
        type: 'string'
      })
      .option('env', {
        description: 'production or test',
        type: 'string',
        default: "test"
      })
  },
  handler: (argv) => {
    subscribe(argv)
  },
}

const testAllocationCommand = {
  command: "test_allocation",
  describe: "Only in test environment, use prepared 5 ethereum accounts do allocation for target address",
  builder: (yargs) => {
    yargs
      .option('target', {
        describe: 'The target address of allocation',
        type: 'string',
        demandOption: true
      })
  },
  handler: (argv) => {
    testAllocation(argv)
  },
}

const generateEtherAccountsCommand = {
  command: "generate_ethers_accounts",
  describe: "generate ethereum accounts for test",
  builder: (yargs) => { },
  handler: (argv) => {
    const res = generateTestAddresses(10);
    console.log(res.map(r => r.privateKey.slice(2)))
  }
}

const allowMintReportCommand = {
  command: "allow_mint_report",
  describe: "allow the process receiving mint reports ",
  builder: (yargs) => { },
  handler: (argv) => {
    allowMintReport()
  }
}

const sendMessageToTokenCommand = {
  command: 'send_message_to_token <message>',
  describe: "send message to token.",
  builder: (yargs) => {
    yargs
      .positional('message', {
        describe: 'message sent to the process',
        type: 'string',
        demandOption: true
      })
  },
  handler: (argv) => {
    sendMessageToToken(argv)
  }
}

const monitorCommand = {
  command: 'monitor <process>',
  describe: 'monitor the target process',
  builder: (yargs) => {
    yargs.positional('process', {
      describe: 'process id',
      type: 'string',
      demandOption: false
    })
  },
  handler: (argv) => {
    monitorProcess(argv)
  }
}

const checkAfterDeployCommand = {
  command: 'check_after_deploy',
  describe: 'Check after deploying the process',
  builder: (yargs) => {
    yargs
      .option('env', {
        description: 'production or test',
        type: 'string',
        default: "test"
      })
  },
  handler: (argv) => {
    checkAfterDeploy(argv)
  }
}

const mintCommand = {
  command: 'mint',
  describe: 'call Mint.Backup method',
  builder: (yargs) => {
    yargs
      .option('target', {
        describe: 'The target address of allocation',
        type: 'string',
        demandOption: false
      })
  },
  handler: (argv) => {
    mint(argv)
  }
}

// 定义子命令
cmd
  .scriptName('npm run helper')
  .command(create_config)
  .command(deployCommand)
  .command(subscribeCommand)
  .command(testAllocationCommand)
  .command(generateEtherAccountsCommand)
  .command(allowMintReportCommand)
  .command(sendMessageToTokenCommand)
  .command(monitorCommand)
  .command(checkAfterDeployCommand)
  .command(mintCommand)
  .demandCommand(1, chalk.red('You must provide at least one command.'))
  .fail((msg, err, yargs) => {
    if (err) {
      console.error(chalk.red('Error:'), err.message);
    } else {
      console.error(chalk.red('Error:'), msg);
    }
    console.log('\n');
    yargs.showHelp();
    process.exit(1);
  })
  .help()
  .argv;
