/* Test Migration*/
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
    return gold.mint(Hero.address, 10000000000000000000000000);
  }).then(function() {
    return Hero.deployed();
  }).then(function(instance) {
    hero = instance;
    return hero.grantAccessMint(CardSwap.address);
  }).then(function() {
    return hero.defineType("Farmer", 0, 0, 56, 1, 15, 1, [10, 22, 8, 15, 25], [1, 2, 1, 1, 2], [1, 3, 1, 2, 3]);
  }).then(function() {
    return deployer.deploy(Dungeon, Hero.address);
  }).then(function() {
    return hero.grantAccessDeposit(Dungeon.address);
  }).then(function() {
    return hero.grantAccessDeploy(Dungeon.address);
  })
};
/**/

/* Mainnet Migration*/

/**/