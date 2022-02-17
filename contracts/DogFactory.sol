// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./DogContract.sol";
import "./DogAdmin.sol";
contract DogFactory is DogContract,DogAdmin {
    mapping(uint256 => address) sireAllowedToAddress;

    uint32[14] cooldowns = [
        uint32(1 minutes),
        uint32(2 minutes),
        uint32(5 minutes),
        uint32(10 minutes),
        uint32(30 minutes),
        uint32(1 hours),
        uint32(2 hours),
        uint32(4 hours),
        uint32(8 hours),
        uint32(16 hours),
        uint32(1 days),
        uint32(2 days),
        uint32(4 days),
        uint32(7 days)
    ];

    event Birth(
        address owner,
        uint256 tokenId,
        uint256 dadId,
        uint256 mumId,
        uint256 genes,
        uint256 generation
    );
    uint256 public constant CREATION_LIMIT_GEN0 = 65535;
    uint256 internal gen0Counter;
    function createDogGen0(uint256 genes) internal  onlyKittyCreator returns (uint256)
    {
        require(gen0Counter<CREATION_LIMIT_GEN0,"gen0 limit exceeded");

        gen0Counter+=1;
        return _createDog(0,0,genes,0,msg.sender);
    }
    function getDogGen0Count() internal view returns(uint256)
    {
        return gen0Counter;
    }
    function _createDog(
        uint256 dadId,
        uint256 mumId,
        uint256 genes,
        uint256 generation,
        address owner
    ) internal returns (uint256) {
        uint16 cooldownIndex = uint16(generation / 2);
        if (cooldownIndex >= cooldowns.length)
            cooldownIndex = uint16(cooldowns.length - 1);

        Dog memory dog = Dog({
            dadId: uint32(dadId),
            mumId: uint32(mumId),
            birthTime: uint64(block.timestamp),
            generation: uint16(generation),
            cooldownIndex: cooldownIndex,
            cooldownEndTime: uint64(block.timestamp),
            genes: genes
        });

        dogs.push(dog);

        uint256 tokenId = dogs.length - 1;
        _safeMint(owner, tokenId);

        emit Birth(owner, tokenId, dadId, mumId, genes, generation);
        return tokenId;
    }

    function breed(uint256 dadId, uint256 mumId) public returns (uint256) {
        require(_eligible(dadId, mumId), "Dog is not eligible to breed");
        Dog storage dad = dogs[dadId];
        Dog storage mum = dogs[mumId];

        _setBreedCooldownEnd(dad);
        _setBreedCooldownEnd(mum);
        _incrementBreedCooldownIndex(dad);
        _incrementBreedCooldownIndex(mum);

        sireApprove(dadId,mumId,false);
        sireApprove(mumId,dadId,false);

        //get kitten attributes
        uint256 newDna=_mixDna(dad.genes,mum.genes,block.timestamp);
        uint256 newGeneration=_getDogGeneration(dad,mum);

        return _createDog(dadId,mumId,newDna,newGeneration,msg.sender);

    }

    function _getDogGeneration(Dog memory dad,Dog memory mum ) internal view returns(uint256){
        if(dad.generation>=mum.generation)
        {
            return dad.generation+1;
        }
        else
        {
            return mum.generation+1;
        }
    }

    
    uint256 public constant NUM_CATTRIBUTE = 10;
    uint256 public constant DNA_LENGTH = 16;
    uint256 public constant RANDOM_DNA_THRESHOLD = 7;

    function _mixDna(
        uint256 dadDna,
        uint256 mumDna,
        uint256 seed
    ) internal returns (uint256) {
        (
            uint256 dnaSeed,
            uint256 randomSeed,
            uint256 randomValues
        ) = _getSeedValues(seed);
        uint256[10] memory geneSizes = [uint256(2), 2, 2, 2, 1, 1, 2, 2, 1, 1];
        uint256[10] memory geneArray;
        uint256 mask = 1;
        uint256 i;
        for (i = NUM_CATTRIBUTE; i > 0; i--) {
            /*
            if the randomSeed digit is >= than the RANDOM_DNA_THRESHOLD
            of 7 choose the random value instead of a parent gene
            Use dnaSeed with bitwise AND (&) and a mask to choose parent gene
            if 0 then Mum, if 1 then Dad
            randomSeed:    8  3  8  2 3 5  4  3 9 8
            randomValues: 62 77 47 79 1 3 48 49 2 8
                           *     *              * *
            dnaSeed:       1  0  1  0 1 0  1  0 1 0
            mumDna:       11 22 33 44 5 6 77 88 9 0
            dadDna:       99 88 77 66 0 4 33 22 1 5
                              M     M D M  D  M                         
            
            childDna:     62 22 47 44 0 6 33 88 2 8
            mask:
            00000001 = 1
            00000010 = 2
            00000100 = 4
            etc
            */

            uint256 randSeedValue = randomSeed % 10;
            uint256 dnaMod = 10**geneSizes[i - 1];
            if (randSeedValue >= RANDOM_DNA_THRESHOLD) {
                geneArray[i - 1] = uint16(randomValues % dnaMod);
            } else {
                if (dnaSeed & mask == 0) {
                    geneArray[i - 1] = uint16(mumDna % dnaMod);
                } else {
                    geneArray[i - 1] = uint16(dadDna % dnaMod);
                }
            }

            //slice off the last gene to expose the next gene
            mumDna = mumDna / dnaMod;
            dadDna = dadDna / dnaMod;
            randomSeed = randomSeed / dnaMod;
            randomValues = randomValues / dnaMod;

            // shift the DNA mask LEFT by 1 bit
            mask = mask * 2;
        }
    }

    function _getSeedValues(uint256 _masterSeed)
        internal
        pure
        returns (
            uint256 dnaSeed,
            uint256 randomSeed,
            uint256 randomValues
        )
    {
        uint256 mod = 2**NUM_CATTRIBUTE - 1;
        dnaSeed = uint16(_masterSeed % mod);

        uint256 randMod = 10**NUM_CATTRIBUTE;
        randomSeed =
            uint256(keccak256(abi.encodePacked(_masterSeed))) %
            randMod;

        uint256 valueMod = 10**DNA_LENGTH;
        randomValues =
            uint256(keccak256(abi.encodePacked(_masterSeed, DNA_LENGTH))) %
            valueMod;
    }

    function _setBreedCooldownEnd(Dog storage dog) internal {
        dog.cooldownEndTime = uint64(
            block.timestamp + cooldowns[dog.cooldownIndex]
        );
    }

    function _incrementBreedCooldownIndex(Dog storage dog) internal {
        if (dog.cooldownIndex < cooldowns.length - 1) {
            dog.cooldownIndex += 1;
        }
    }

    function _eligible(uint256 dadId, uint256 mumId)
        internal
        isApprovedOrOwner(dadId)
        returns (bool)
    {
        require(isOnlyOnwer(dadId) || isApproveForSiring(dadId, mumId));
        require(readyToBreed(dadId), "dad dog not ready to breed");
        require(readyToBreed(mumId), "mum dog not ready to breed");
        return true;
    }

    function readyToBreed(uint256 tokenId) public returns (bool) {
        Dog memory dog = getDog(tokenId);
        return dog.cooldownEndTime <= block.timestamp;
    }

    function isApproveForSiring(uint256 dadId, uint256 mumId)
        public
        view
        returns (bool)
    {
        return sireAllowedToAddress[dadId] == ownerOf(mumId);
    }

    // dadId is sire
    //mumId is marton
    function sireApprove(
        uint256 dadId,
        uint256 mumId,
        bool isApprove
    ) public isApprovedOrOwner(dadId) returns (bool) {
        if (isApprove) {
            sireAllowedToAddress[dadId] = ownerOf(mumId);
        } else {
            delete sireAllowedToAddress[dadId];
        }
    }


    function dogsOf(address owner) internal returns(uint256[] memory)
    {
        uint256 countDogs=balanceOf(owner);
        if(countDogs==0)
        {
            return new uint256[](0) ;
        }

        uint256[] memory ids=new uint256[](countDogs);
        uint256 i;
        uint256 count;
        while(count<countDogs || i<dogs.length)
        {
            if(ownerOf(i) ==owner)
            {
                ids[count]=i;
                count+=1;
            }
            i+=1;
        }
        return ids;
    }
}
