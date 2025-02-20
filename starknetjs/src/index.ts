import {
  Account,
  RpcProvider,
  Contract,
} from "starknet";
import "dotenv/config";
import labelsAbi from "../labels.json" with { type: 'json' };

const DEPLOYED_CONTRACT =
  "0x042de0e88b8d70b02ff6303fdb69cec5718154db91b8c53a58de047dfcbc41c0";

const getTotalSupply = async (contract: Contract) => {
  const totalSupply = await contract.total_supply();
  console.log(`The total supply is: ${totalSupply}`);
};

const getTokenUri = async (contract: Contract, tokenId: number) => {
  const uri = await contract.get_token_uri(tokenId);
  console.log(`The URI of the token ${tokenId} is: ${uri}`);
};

const tokenBalance = async (contract: Contract, address: string) => {
  const tokenBalance = await contract.balance_of(address);
  console.log(`The account ${address} has: ${tokenBalance} tokens`);
};

const mintNft = async (
  contract: Contract,
  account: Account,
  provider: RpcProvider,
  recipient: string,
  uri: string
) => {
  // Transaction with fees paid in ETH
  const mintCall = contract.populate("mint_item", { recipient, uri });
  const { transaction_hash: transferTxHash } = await account.execute(mintCall, {
    version: 3, // version 3 to pay fees in STRK. To pay fees in ETH remove the version field
  });
  console.log(`Minting NFT with transaction hash: ${transferTxHash}`);
  // Wait for the invoke transaction to be accepted on Starknet
  const receipt = await provider.waitForTransaction(transferTxHash);
  console.log(receipt);
};

const getContractName = async (contract: Contract) => {
  const name = await contract.name();
  console.log("Contract's name ", name);
};

const main = async () => {
  // Initialize provider
  const provider = new RpcProvider({
    nodeUrl: process.env.STARKNET_RPC_URL,
  });

  // Connect to the account
  const account = new Account(
    provider,
    process.env.STARKNET_ADDRESS,
    process.env.STARKNET_PRIVATE_KEY
  );

  // Connect the contract
  const erc721 = new Contract(labelsAbi, DEPLOYED_CONTRACT, provider);
  erc721.connect(account);

  //await getContractName(erc721);
  

  // Mint NFTs ERC721
  /* await mintNft(
    erc721,
    account,
    provider,
    account.address,
    "NFT1"
  ); */

  await tokenBalance(erc721, account.address); 

  await getTokenUri(erc721, 1);

  await getTotalSupply(erc721);
};

main().catch(console.error);
