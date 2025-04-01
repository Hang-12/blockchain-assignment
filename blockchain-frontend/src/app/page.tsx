'use client';

import { useEffect, useState } from "react";
import { retailerContract } from "../utils/web3";
import ConnectWalletButton from "../components/ConnectWalletButton";

const Home = () => {
  const [owner, setOwner] = useState<string | null>(null);

  useEffect(() => {
    const fetchOwner = async () => {
      if (!retailerContract) {
        console.error("Retailer contract is not initialized.");
        setOwner(null); // Handle error by setting the owner to null
        return;
      }

      try {
        // Call the owner method from the contract
        const ownerAddress: string = await retailerContract.methods
          .owner()
          .call();
        setOwner(ownerAddress);
      } catch (error) {
        console.error("Error fetching owner:", error);
        setOwner(null); // Handle error by setting the owner to null
      }
    };

    fetchOwner();
  }, []); // Empty dependency array ensures this runs once on mount

  return (
    <div className="container">
      <h1>Retailer DApp</h1>
      <p>Contract Owner: {owner || "Loading..."}</p>
      <ConnectWalletButton />
    </div>
  );
};

export default Home;
