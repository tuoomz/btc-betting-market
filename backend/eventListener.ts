import { ethers } from "ethers";
import { PrismaClient } from "@prisma/client";
import { abi } from "./../out/BettingContract.sol/BettingContract.json";

const providerUrl = process.env.ALCHEMY_URL || "";
const provider = new ethers.JsonRpcProvider(providerUrl);

const prisma = new PrismaClient();

async function listenForEvents() {
  const contractAddress = process.env.BETTING_CONTRACT_ADDRESS || ""; // Replace with your contract address

  const contract = new ethers.Contract(contractAddress, abi, provider);

  contract.on(
    "BetProposed",
    async (betId: number, proposer: string, betAmount: number, event: any) => {
      try {
        await prisma.event.create({
          data: {
            hash: event.log.hash,
            name: "BetProposed",
            address: contractAddress,
            data: { betId, proposer, betAmount },
          },
        });

        console.log("BetProposed event stored:", {
          betId,
          proposer,
          betAmount,
        });
      } catch (error) {
        console.error("Error storing BetProposed event:", error);
      }
    }
  );

  contract.on(
    "BetAccepted",
    async (betId: number, acceptor: string, betAmount: number, event: any) => {
      try {
        await prisma.event.create({
          data: {
            hash: event.log.hash,
            name: "BetAccepted",
            address: contractAddress,
            data: { betId, acceptor, betAmount },
          },
        });

        console.log("BetAccepted event stored:", {
          betId,
          acceptor,
          betAmount,
        });
      } catch (error) {
        console.error("Error storing BetAccepted event:", error);
      }
    }
  );

  contract.on(
    "BetSettled",
    async (betId: number, winner: string, winnings: number, event: any) => {
      try {
        await prisma.event.create({
          data: {
            hash: event.log.hash,
            name: "BetSettled",
            address: contractAddress,
            data: { betId, winner, winnings },
          },
        });

        console.log("BetSettled event stored:", { betId, winner, winnings });
      } catch (error) {
        console.error("Error storing BetSettled event:", error);
      }
    }
  );
}

listenForEvents()
  .then(() => console.log("Event listener started."))
  .catch((error) => console.error("Error starting event listener:", error));
