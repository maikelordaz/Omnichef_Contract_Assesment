const { network, ethers } = require("hardhat")
const { verify } = require("../utils/verify")
const { developmentChains, networkConfig } = require("../helper-hardhat-config")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    log("--------------- Deploying OmniChef Contract... ---------------")

    const waitBlockConfirmations = developmentChains.includes(network.name)
        ? 1
        : network.chainId.blockConfirmations

    const args = []

    const omniChef = await deploy("OmniChef", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: waitBlockConfirmations,
    })
    log("--------------- OmniChef Contract deployed! ---------------")

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("--------------- Verifying! ---------------")
        await verify(omniChef.address, args)
        log("--------------- Verify process finished! ---------------")
    } else {
        log("--------------- Localhost detected. Nothing to verify ---------------")
    }
}

module.exports.tags = ["all", "chef", "main"]
