import { SlowTreeContractArtifact, SlowTreeContract } from "../contracts/artifacts/SlowTree.js"
import { ContractDeployer, Fr, Note, PXE, waitForPXE, TxStatus, createPXEClient, getContractInstanceFromDeployParams, AccountWalletWithPrivateKey, AztecAddress, ExtendedNote } from "@aztec/aztec.js";
import { getInitialTestAccountsWallets } from "@aztec/accounts/testing"
import { LogicContractContract } from "../contracts/artifacts/LogicContract.js";
import { ProxyContract } from "../contracts/artifacts/Proxy.js";


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
    let slowUpdatesAddress: AztecAddress
    let proxyContract: ProxyContract
    let logicContract: LogicContractContract

    beforeAll(async () => {
        pxe = await setupSandbox();

        wallets = await getInitialTestAccountsWallets(pxe);
        sender = wallets[0]
    }, 40000)

    it("Deploys the Slow tree contract", async () => {
        const salt = Fr.random();
        const publicKey = sender.getCompleteAddress().publicKey
        // const deployArgs = sender.getCompleteAddress().address

        const deploymentData = getContractInstanceFromDeployParams(SlowTreeContractArtifact, [], salt, publicKey);
        const deployer = new ContractDeployer(SlowTreeContractArtifact, pxe, publicKey);
        const tx = deployer.deploy().send({ contractAddressSalt: salt })
        const receiptAfterMined = await tx.wait();
        slowUpdatesAddress = deploymentData.address
        console.log("Slow tree deployed")
        // expect(receiptAfterMined).toEqual(
        //     expect.objectContaining({
        //         status: TxStatus.MINED,
        //         error: '',
        //         contractAddress: deploymentData.completeAddress.address,
        //     }),
        // );
    })

    it("deploys other contracts", async () => {

        logicContract = await LogicContractContract.deploy(sender).send().deployed()
        let tx = await ProxyContract.deploy(sender, sender.getAddress(), slowUpdatesAddress).send()
        proxyContract = await tx.deployed()

        let note = new Note([slowUpdatesAddress.toField()])
        // from here: https://github.com/AztecProtocol/aztec-packages/blob/e6d65a7fe9ebe855dcac389775aae2ccc3fa311f/noir-projects/aztec-nr/field-note/src/field_note.nr#L57
        const noteTypeId = new Fr(7010510110810078111116101);
        let storageSlot = new Fr(2)
        let extendedNote = new ExtendedNote(note,
            sender.getAddress(),
            proxyContract.address,
            storageSlot,
            noteTypeId,
            await tx.getTxHash())

        await pxe.addNote(extendedNote)
        console.log("contracts deployed")
    })

    it("can call the counter function through the proxy", async () => {

        let slowUpdateInitReceipt = await proxyContract.methods.init_slow_tree(logicContract.address).send().wait()
        let addReceipt = await proxyContract.methods.call_counter().send().wait()
        let count = await proxyContract.methods.get_count().view()
        console.log(count)

    })

});