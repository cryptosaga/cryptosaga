var Card = artifacts.require("CryptoSagaCard");
var Presale = artifacts.require("Presale");
var Gold = artifacts.require("Gold");
var Hero = artifacts.require("CryptoSagaHero");
var CardSwap = artifacts.require("CryptoSagaCardSwapVer1");

module.exports = function(deployer) {
  var card, gold, hero, cardSwap;
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
    return Hero.deployed();
  }).then(function(instance) {
    hero = instance;
    return hero.grantAccessMint(CardSwap.address);
  });
};