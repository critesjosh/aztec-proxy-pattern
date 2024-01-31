import { SlowTreeContractArtifact, SlowTreeContract } from "../contracts/artifacts/SlowTree.js"
import { ContractDeployer, Fr, PXE, waitForPXE, TxStatus, createPXEClient, getContractDeploymentInfo, AccountWalletWithPrivateKey } from "@aztec/aztec.js";
import { getInitialTestAccountsWallets } from "@aztec/accounts/testing"

const setupSandbox = async () => {
    const { PXE_URL = 'http://localhost:8080' } = process.env;
    const pxe = createPXEClient(PXE_URL);
    await waitForPXE(pxe);
    return pxe;
};

describe("Voting", () => {
    let pxe: PXE;
    let sender: AccountWalletWithPrivateKey
    let wallets: AccountWalletWithPrivateKey[]

    beforeAll(async () => {
        pxe = await setupSandbox();

        wallets = await getInitialTestAccountsWallets(pxe);
        sender = wallets[0]
    }, 40000)

    it("Deploys the Slow tree contract", async () => {
        const salt = Fr.random();
        const publicKey = sender.getCompleteAddress().publicKey
        // const VotingContractArtifact = SlowTreeContractArtifact
        // const deployArgs = sender.getCompleteAddress().address

        const deploymentData = getContractDeploymentInfo(SlowTreeContractArtifact, [], salt, publicKey);
        const deployer = new ContractDeployer(SlowTreeContractArtifact, pxe, publicKey);
        const tx = deployer.deploy().send({ contractAddressSalt: salt })
        const receipt = await tx.getReceipt();

        expect(receipt).toEqual(
            expect.objectContaining({
                status: TxStatus.PENDING,
                error: '',
            }),
        );

        const receiptAfterMined = await tx.wait();

        expect(receiptAfterMined).toEqual(
            expect.objectContaining({
                status: TxStatus.MINED,
                error: '',
                contractAddress: deploymentData.completeAddress.address,
            }),
        );
    })

    // it("It casts a vote", async () => {
    //     const candidate = new Fr(1)

    //     const contract = await EasyPrivateVotingContract.deploy(wallets[0], sender.getCompleteAddress().address).send().deployed();
    //     const tx = await contract.methods.cast_vote(candidate).send().wait();
    //     let count = await contract.methods.get_vote(candidate).view();
    //     expect(count).toBe(1n);
    // })

});