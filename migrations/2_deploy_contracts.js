/* Test Migration
var Card = artifacts.require("CryptoSagaCard");
var Presale = artifacts.require("Presale");
var Gold = artifacts.require("Gold");
var Hero = artifacts.require("CryptoSagaHero");
var CardSwap = artifacts.require("CryptoSagaCardSwapVer1");
var Dungeon = artifacts.require("ExampleDungeon");

module.exports = function(deployer) {
  var card, gold, hero, cardSwap, dungeon;
  deployer.then(function() {
    return deployer.deploy(Card);
  }).then(function() {
    return deployer.deploy(Presale, '0x6eA5F3284cCB1a1878167c640A42B3C9b6e5930b', Card.address, 1517356800, 1522497600, 5000000000000000, 300000000000000);
  }).then(function() {
    return deployer.deploy(Gold);
  }).then(function() {
    return deployer.deploy(Hero, Gold.address);
  }).then(function() {
    return deployer.deploy(CardSwap, Hero.address, Card.address);
  }).then(function() {
    return Card.deployed();
  }).then(function(instance) {
    card = instance;
    return card.grantAccessMint(Presale.address);
  }).then(function() {
    return card.setCryptoSagaCardSwapContract(CardSwap.address);
  }).then(function() {
    return Gold.deployed();
  }).then(function(instance) {
    gold = instance;
    return gold.grantAccessMint(Hero.address);
  }).then(function() {
    return gold.mint(Hero.address, 30000000000000000000000000);
  }).then(function() {
    return Hero.deployed();
  }).then(function(instance) {
    hero = instance;
    return hero.grantAccessMint(CardSwap.address);
  }).then(function() {
    // Name, Rank, Race, Age, Type, Max Level, Aura, Stats.
    // Race => 0: Human, 1: Celestial, 2: Demon, 3: Elf, 4: Dark Elf, 5: Yogoe, 6: Furry, 7: Dragonborn, 8: Undead, 9: Goblin, 10: Troll, 11: Slime, and more to come.
    // Type => 0: Fighter, 1: Rogue, 2: Mage.
    // Aura => 0: Water, 1: Fire, 2: Nature, 3: Light, 4: Darkness.
    return hero.defineType("Demon Prince", 4, 2, 12666, 0, 99, 4, [97, 70, 80, 33, 110], [9, 5, 8, 3, 7], [9, 8, 8, 6, 9]);
  }).then(function() {
    return hero.defineType("Dragon Queen", 4, 7, 375, 2, 99, 1, [95, 60, 45, 75, 85], [9, 6, 8, 3, 6], [10, 10, 9, 5, 6]);
  }).then(function() {
    return hero.defineType("Kumiho", 4, 5, 999, 1, 99, 2, [110, 55, 95, 40, 60], [10, 4, 9, 3, 6], [12, 6, 12, 4, 6]);
  }).then(function() {
    return hero.defineType("Celestial Mage", 3, 3, 176, 2, 75, 3, [45, 40, 45, 70, 60], [5, 3, 6, 4, 6], [6, 6, 6, 8, 6]);
  }).then(function() {
    return hero.defineType("Dragon Priestess", 3, 7, 210, 2, 75, 1, [77, 45, 35, 50, 53], [7, 4, 5, 3, 5], [8, 6, 6, 6, 6]);
  }).then(function() {
    return hero.defineType("Privateer Captain", 3, 0, 33, 1, 75, 0, [42, 45, 50, 55, 58], [4, 3, 3, 8, 6], [5, 5, 6, 9, 7]);
  }).then(function() {
    return hero.defineType("Succubus", 3, 2, 197, 0, 75, 4, [15, 60, 40, 80, 55], [2, 5, 4, 7, 6], [2, 9, 5, 10, 6]);
  }).then(function() {
    return hero.defineType("Crimson Rogue", 3, 0, 39, 1, 75, 1, [75, 40, 60, 35, 40], [8, 4, 5, 3, 4], [10, 5, 8, 4, 5]);
  }).then(function() {
    return deployer.deploy(Dungeon, Hero.address);
  }).then(function() {
    return hero.grantAccessDeposit(Dungeon.address);
  }).then(function() {
    return hero.grantAccessDeploy(Dungeon.address);
  })
};
*/

/* Rinkeby Testnet Migration

var Card = artifacts.require("CryptoSagaCard");
var Presale = artifacts.require("Presale");
var Gold = artifacts.require("Gold");
var Hero = artifacts.require("CryptoSagaHero");
var CardSwap = artifacts.require("CryptoSagaCardSwapVer1");

module.exports = function(deployer) {
  var card, gold, hero;
  deployer.then(function() {
    return deployer.deploy(Gold);
  }).then(function() {
    return deployer.deploy(Hero, Gold.address);
  }).then(function() {
    return deployer.deploy(CardSwap, Hero.address, '0xc99ec9ede781599e13d7a31e937648260fd1e2b1');
  }).then(function() {
    return Card.at('0xc99ec9ede781599e13d7a31e937648260fd1e2b1');
  }).then(function(instance) {
    card = instance;
    return card.setCryptoSagaCardSwapContract(CardSwap.address);
  }).then(function() {
    return Gold.deployed();
  }).then(function(instance) {
    gold = instance;
    return gold.grantAccessMint(Hero.address);
  }).then(function() {
    return gold.mint(Hero.address, 30000000000000000000000000);
  }).then(function() {
    return Hero.deployed();
  }).then(function(instance) {
    hero = instance;
    return hero.grantAccessMint(CardSwap.address);
  }).then(function() {
    // Name, Rank, Race, Age, Type, Max Level, Aura, Stats.
    // Race => 0: Human, 1: Celestial, 2: Demon, 3: Elf, 4: Dark Elf, 5: Yogoe, 6: Furry, 7: Dragonborn, 8: Undead, 9: Goblin, 10: Troll, 11: Slime, and more to come.
    // Type => 0: Fighter, 1: Rogue, 2: Mage.
    // Aura => 0: Water, 1: Fire, 2: Nature, 3: Light, 4: Darkness.
    return hero.defineType("Demon Prince", 4, 2, 12666, 0, 99, 4, [97, 70, 80, 33, 110], [9, 5, 8, 3, 7], [9, 8, 8, 6, 9]);
  }).then(function() {
    return hero.defineType("Dragon Queen", 4, 7, 375, 2, 99, 1, [95, 60, 45, 75, 85], [9, 6, 8, 3, 6], [10, 10, 9, 5, 6]);
  }).then(function() {
    return hero.defineType("Kumiho", 4, 5, 999, 1, 99, 2, [110, 55, 95, 40, 60], [10, 4, 9, 3, 6], [12, 6, 12, 4, 6]);
  }).then(function() {
    return hero.defineType("Celestial Mage", 3, 3, 176, 2, 75, 3, [45, 40, 45, 70, 60], [5, 3, 6, 4, 6], [6, 6, 6, 8, 6]);
  }).then(function() {
    return hero.defineType("Dragon Priestess", 3, 7, 210, 2, 75, 1, [77, 45, 35, 50, 53], [7, 4, 5, 3, 5], [8, 6, 6, 6, 6]);
  }).then(function() {
    return hero.defineType("Privateer Captain", 3, 0, 33, 1, 75, 0, [42, 45, 50, 55, 58], [4, 3, 3, 8, 6], [5, 5, 6, 9, 7]);
  }).then(function() {
    return hero.defineType("Succubus", 3, 2, 197, 0, 75, 4, [15, 60, 40, 80, 55], [2, 5, 4, 7, 6], [2, 9, 5, 10, 6]);
  }).then(function() {
    return hero.defineType("Crimson Rogue", 3, 0, 39, 1, 75, 1, [75, 40, 60, 35, 40], [8, 4, 5, 3, 4], [10, 5, 8, 4, 5]);
  })
};

*/

/* Mainnet Migration
var Card = artifacts.require("CryptoSagaCard");
var Presale = artifacts.require("Presale");
var Gold = artifacts.require("Gold");
var Hero = artifacts.require("CryptoSagaHero");
var CardSwap = artifacts.require("CryptoSagaCardSwapVer1");

module.exports = function(deployer) {
  var card, gold, hero;
  deployer.then(function() {
    return deployer.deploy(Gold);
  }).then(function() {
    return deployer.deploy(Hero, Gold.address);
  }).then(function() {
    return deployer.deploy(CardSwap, Hero.address, '0x1b5242794288b45831ce069c9934a29b89af0197');
  }).then(function() {
    return Card.at('0x1b5242794288b45831ce069c9934a29b89af0197');
  }).then(function(instance) {
    card = instance;
    return card.setCryptoSagaCardSwapContract(CardSwap.address);
  }).then(function() {
    return Gold.deployed();
  }).then(function(instance) {
    gold = instance;
    return gold.grantAccessMint(Hero.address);
  }).then(function() {
    return gold.mint(Hero.address, 30000000000000000000000000);
  }).then(function() {
    return Hero.deployed();
  }).then(function(instance) {
    hero = instance;
    return hero.grantAccessMint(CardSwap.address);
  }).then(function() {
    // Name, Rank, Race, Age, Type, Max Level, Aura, Stats.
    // Race => 0: Human, 1: Celestial, 2: Demon, 3: Elf, 4: Dark Elf, 5: Yogoe, 6: Furry, 7: Dragonborn, 8: Undead, 9: Goblin, 10: Troll, 11: Slime, and more to come.
    // Type => 0: Fighter, 1: Rogue, 2: Mage.
    // Aura => 0: Water, 1: Fire, 2: Nature, 3: Light, 4: Darkness.
    return hero.defineType("Demon Prince", 4, 2, 12666, 0, 99, 4, [97, 70, 80, 33, 110], [9, 5, 8, 3, 7], [9, 8, 8, 6, 9]);
  }).then(function() {
    return hero.defineType("Dragon Queen", 4, 7, 375, 2, 99, 1, [95, 60, 45, 75, 85], [9, 6, 8, 3, 6], [10, 10, 9, 5, 6]);
  }).then(function() {
    return hero.defineType("Kumiho", 4, 5, 999, 1, 99, 2, [110, 55, 95, 40, 60], [10, 4, 9, 3, 6], [12, 6, 12, 4, 6]);
  }).then(function() {
    return hero.defineType("Celestial Mage", 3, 3, 176, 2, 75, 3, [45, 40, 45, 70, 60], [5, 3, 6, 4, 6], [6, 6, 6, 8, 6]);
  }).then(function() {
    return hero.defineType("Dragon Priestess", 3, 7, 210, 2, 75, 1, [77, 45, 35, 50, 53], [7, 4, 5, 3, 5], [8, 6, 6, 6, 6]);
  }).then(function() {
    return hero.defineType("Privateer Captain", 3, 0, 33, 1, 75, 0, [42, 45, 50, 55, 58], [4, 3, 3, 8, 6], [5, 5, 6, 9, 7]);
  }).then(function() {
    return hero.defineType("Succubus", 3, 2, 197, 0, 75, 4, [15, 60, 40, 80, 55], [2, 5, 4, 7, 6], [2, 9, 5, 10, 6]);
  }).then(function() {
    return hero.defineType("Crimson Rogue", 3, 0, 39, 1, 75, 1, [75, 40, 60, 35, 40], [8, 4, 5, 3, 4], [10, 5, 8, 4, 5]);
  })
};
*/


/* Mainnet Add hero */
var Hero = artifacts.require("CryptoSagaHero");

module.exports = function(deployer) {
  var hero;
  deployer.then(function() {
    return Hero.at('0xabc7e6c01237e8eef355bba2bf925a730b714d5f');
  }).then(function(instance) {
    hero = instance;
    // Name, Rank, Race, Age, Type, Max Level, Aura, Stats.
    // Race => 0: Human, 1: Celestial, 2: Demon, 3: Elf, 4: Dark Elf, 5: Yogoe, 6: Furry, 7: Dragonborn, 8: Undead, 9: Goblin, 10: Troll, 11: Slime, and more to come.
    // Type => 0: Fighter, 1: Rogue, 2: Mage.
    // Aura => 0: Water, 1: Fire, 2: Nature, 3: Light, 4: Darkness.
    return hero.defineType("Dragon Queen", 4, 7, 375, 2, 99, 1, [95, 60, 45, 75, 85], [9, 6, 8, 3, 6], [10, 10, 9, 5, 6]);
  }).then(function() {
    return hero.defineType("Kumiho", 4, 5, 999, 1, 99, 2, [110, 55, 95, 40, 60], [10, 4, 9, 3, 6], [12, 6, 12, 4, 6]);
  }).then(function() {
    return hero.defineType("Celestial Mage", 3, 3, 176, 2, 75, 3, [45, 40, 45, 70, 60], [5, 3, 6, 4, 6], [6, 6, 6, 8, 6]);
  }).then(function() {
    return hero.defineType("Dragon Priestess", 3, 7, 210, 2, 75, 1, [77, 45, 35, 50, 53], [7, 4, 5, 3, 5], [8, 6, 6, 6, 6]);
  }).then(function() {
    return hero.defineType("Privateer Captain", 3, 0, 33, 1, 75, 0, [42, 45, 50, 55, 58], [4, 3, 3, 8, 6], [5, 5, 6, 9, 7]);
  }).then(function() {
    return hero.defineType("Succubus", 3, 2, 197, 0, 75, 4, [15, 60, 40, 80, 55], [2, 5, 4, 7, 6], [2, 9, 5, 10, 6]);
  }).then(function() {
    return hero.defineType("Crimson Rogue", 3, 0, 39, 1, 75, 1, [75, 40, 60, 35, 40], [8, 4, 5, 3, 4], [10, 5, 8, 4, 5]);
  })
};
/**/