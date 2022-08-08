# TxAnalysis

#### 目的
获取以太坊合约信息，爬取合约源码，并对合约及交易信息进行分析

#### 数据获取

1.参考[论文(ICSE'20)](https://dl.acm.org/doi/abs/10.1145/3377811.3380364)的合约数据集构建方法，我们从Google BigQuery的以太坊公共数据集进行查询

(使用[BigQuery沙盒](https://console.cloud.google.com)可以不创建绑定信用卡的结算账号直接查询)

获取合约地址，统计合约调用次数，为减少合约分析的数量，我们选取被调用超过8000次的合约，查询如下：
```
SELECT contracts.address, COUNT(1) AS tx_count
FROM `bigquery-public-data.crypto_ethereum.contracts` AS contracts
JOIN `bigquery-public-data.crypto_ethereum.transactions` AS transactions ON (transactions.to_address = contracts.address)
GROUP BY contracts.address HAVING COUNT(1) > 8000
ORDER BY tx_count DESC
```

增加以下筛选条件进一步筛选ERC20合约和ERC721合约

`WHERE contracts.is_erc20 = true`

`WHERE contracts.is_erc721 = true`


获取的数据见`raw_data/gt8000-all.csv, raw_data/gt8000-erc20.csv, raw_data/gt8000-erc721.csv`(命名规则：`调用次数-筛选条件.csv`)

2.从[Etherscan](https://etherscan.io/)获取合约源码及信息，使用了[py-etherscan-api](https://github.com/corpetty/py-etherscan-api)包，脚本位于`raw_data/script/get_contracts.py`

爬取的结果位于`raw_data/jsons/`，json数据格式如下：

```
// File: contract_address.json
{
    "SourceCode": "",
    "ABI": "",
    "ContractName": "",
    "CompilerVersion": "",
    "OptimizationUsed": "",
    "Runs": "",
    "ConstructorArguments": "",
    "EVMVersion": "",
    "Library": "",
    "LicenseType": "",
    "Proxy": "",
    "Implementation": "",
    "SwarmSource": ""
}
```

#### 数据处理

1. 从json数据中提取SourceCode字段，脚本位于`raw_data/script/extract.py`，处理结果将保存到`raw_data/codes/`目录下，以`合约地址.sol`命名

2. 对合约按照erc20和erc721类型进行标记，脚本位于`raw_data/script/mark.py`，生成的结果将保存为`raw_data/marked.xlsx`

3. 将`合约地址.sol`重命名为`调用次数排名(降序)_调用次数_合约地址.sol`，脚本位于`raw_data/script/rename.py`，处理完成的合约位于`contracts/`下

4. 部分合约使用Vyper语言编写，对`contracts/`下的合约使用`raw_data/script/fix.sh`脚本过滤，invalid_contract手动修正，共计86个Vyper合约，其中编号55、70是反编译获得

5. 部分合约包含多个文件，解析不完全，使用`raw_data/script/reparser.py`脚本处理，涉及1746个合约

6. 部分合约源代码存在换行符等符号错误，使用`raw_data/script/filter.sh`脚本处理

7. 根据代码相似度对源码进行分类，使用`raw_data/script/group.sh`脚本处理

8. 将分类后的合约放入不同文件夹中，使用`raw_data/script/group.py`脚本处理

9. 将分类信息写入contract_info，使用`raw_data/script/write_group.py`脚本处理

#### 一些结果

对TOP100合约的分类和功能描述情况详见`contract_info.xlsx`

数量及分类如下：
```
Token: 41个，代币合约，包括ERC20和非ERC20代币
DEX: 20个，去中心化交易所
MEV Bot: 8个，套利机器人，地址多以0x000000...开头，可能为了减少gas费用
NFTM: 2个， OpenSea NFT交易市场
ICO: 3个，众筹合约，均疑似庞氏骗局
GAME: 2个，EasyClub金融游戏，Dice2Win博彩游戏
NFT: 1个，CryptoKitties
其他类型单独标注
```
Top1合约调用次数占比13.99%

Top10合约调用次数占比累计37.49%，第9个合约起，每个合约调用次数占比＜1%

Top100合约调用次数占比累计57.67%

Top637合约调用次数占比累计75.73%，第638个合约起，每个合约的调用次数占比≤0.01%