import { ethers } from "ethers";
import { abi } from "./../out/BettingContract.sol/BettingContract.json";
import dotenv from "dotenv";
dotenv.config();
// Generated types with typechain
import { BettingContract } from "../out/types/ethers-contracts";

const providerUrl = process.env.ALCHEMY_URL || "";
const provider = new ethers.JsonRpcProvider(providerUrl);
const contractAddress = process.env.BETTING_CONTRACT_ADDRESS || "";
const privateKey = process.env.PRIVATE_KEY || "";
const contract = new ethers.Contract(contractAddress, abi, provider);
const wallet = new ethers.Wallet(privateKey, provider);
const connectedContract = contract.connect(wallet) as BettingContract;

// Function to settle a bet
async function settleBet(betId: number) {
  
  const tx = await connectedContract.settleBet(betId);
  
  await tx.wait();

  console.log(`Bet settled: betId=${betId}`);
}

// Loop through each bet in the struct and check if the closing time has passed and the bet is still active
async function checkBets() {
  const totalBets = Number(await connectedContract.totalBets());
  if (totalBets == 0) {
    console.log("No bets to check");
    return;
  }

  for (let betId = 0; betId < totalBets; betId++) {
    const bet = await connectedContract.bets(betId);

    if (bet.closingTime <= Math.floor(Date.now() / 1000) && bet.isActive) {
      console.log(`Bet ${betId} has passed its closing time`);
      await settleBet(betId);
    }
  }
}
// Listen for new blocks
provider.on("block", () => {
  console.log("New block mined! Checking bets...");
  checkBets().catch((error) => console.error(error));
});
