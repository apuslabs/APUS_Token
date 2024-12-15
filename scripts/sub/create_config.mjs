// import chalk from 'chalk';

export default async function createConfig(argv) {

  const result = await asyncWithBreathingLog(fetchData, { url: 'https://jsonplaceholder.typicode.com/posts/1' }, 'Fetching data');
  console.log('Result:', result); // 
}