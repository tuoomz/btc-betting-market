## Overview
The betting contract in this project enables users to propose, accept, and settle bets. The settlement process relies on a Chainlink oracle to determine the Bitcoin price. Foundry was chosen as the development framework over Hardhat, and the test folder includes Foundry tests that can be executed using the command "forge test --fork-url <your_rpc_url>". The backend folder contains code for the event listener and the settlement bot.

I implemented Chainlink for price feeds, Prisma for ORM, and MongoDB as the database. I also used TypeChain to generate TypeScript types for smart contracts.

## Feature Improvements

* The current contracts allow you to configure the token on init. An improvement would be to enable users to use any token they like and automatically swap it for the betting token. This would require an integration with a DEX.

* Introduce multiple betting assets instead of just Bitcoin. Users could place bets on various cryptocurrencies, stocks, commodities, or even political events. This would diversify the platform's offerings and cater to different interests.

* Allow users to accept bets with different amounts rather than requiring a 1:1 bet amount. This would give participants the flexibility to bet different amounts based on their confidence in the outcome. So a user can partially match a bet if they don't want to bet the full amount.

* Implement a betting pool system where users can contribute to a common pool, and bets are matched based on available liquidity. This would increase liquidity, allowing users to easily find counterparties for their bets.

* Explore integration with decentralized finance (DeFi) protocols such as lending platforms or yield farming protocols. This could provide additional earning opportunities for users while the bet funds are tied up in the contract. This would be useful for long-dated bets but would also add another layer of risk to the protocol.

* Integrate with other decentralised betting protocols to enable users to access and compare the best prices across multiple protocols, maximizing their potential winnings.

## Tech Improvements

### Bot

* The private key is stored in the env var. A better way to do this would be to use AWS KMS to store the key. Instead of accessing the key directly, you use the KMS SDK to fetch the key when needed. This allows your software program to securely retrieve and use the private key without directly exposing it.

* Ensure the use of robust logging software that notifies the user promptly in the event of script errors or failures. Additionally, implement a mechanism to automatically restart the script upon error detection.

### Event Listener

* Implement a mechanism to backfill all events in case of an extended downtime period. Additionally, perform periodic checks to identify and add any dropped events to the database.

### Protocol

* Using upgradable contracts would be useful for this protocol as it allows for future enhancements and bug fixes without disrupting the existing functionality or requiring users to migrate to new contracts. It provides flexibility and adaptability, ensuring that the protocol can evolve over time to meet changing requirements and address potential security vulnerabilities.

* The current implementation relies on the Chainlink oracle for obtaining the current price of Bitcoin. However, if there is a delay in executing the settlement, it may lead to potential issues with obtaining the accurate current price. While Chainlink does offer historical price data, incorporating it would add complexity to the implementation, which was avoided in this case as it will only be an issue if the bot fails.

* You could put an authentication guard on the settle bet function, so only a certain address would be able to call it.