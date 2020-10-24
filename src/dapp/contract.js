import FlightSuretyApp from "../../build/contracts/FlightSuretyApp.json";
import FlightSuretyData from "../../build/contracts/FlightSuretyData.json";
import Config from "./config.json";
import Web3 from "web3";

export default class Contract {
  constructor(network, callback) {
    let config = Config[network];
    this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
    this.flightSuretyApp = new this.web3.eth.Contract(
      FlightSuretyApp.abi,
      config.appAddress
    );
    this.flightSuretyData = new this.web3.eth.Contract(
      FlightSuretyData.abi,
      config.dataAddress
    );
    this.initialize(callback);
    this.owner = null;
    this.airlines = [];
    this.passengers = [];
  }

  initialize(callback) {
    this.web3.eth.getAccounts((error, accts) => {
      this.owner = accts[0];

      let counter = 1;

      while (this.airlines.length < 5) {
        this.airlines.push(accts[counter++]);
      }

      while (this.passengers.length < 5) {
        this.passengers.push(accts[counter++]);
      }

      callback();
    });
  }

  isOperational(callback) {
    let self = this;
    self.flightSuretyApp.methods
      .isOperational()
      .call({ from: self.owner }, callback);
  }

  registerAirline(airline, name, callback) {
    let self = this;
    let payload = {
      airline: airline,
      nameOfAirline: name,
    };
    self.flightSuretyApp.methods
      .registerAirline(payload.airline, payload.nameOfAirline)
      .send({ from: self.owner, gas: 999999 }, (error, result) => {
        callback(error, payload);
      });
  }

  fund(airline, callback) {
    let self = this;
    let payload = {
      airline: airline,
    };
    self.flightSuretyApp.methods.fund(payload.airline).send(
      {
        from: payload.airline,
        value: this.web3.utils.toWei("10", "ether"),
      },
      (error, result) => {
        callback(error, payload);
      }
    );
  }

  registerFlight(airline, flight, callback) {
    let self = this;
    let payload = {
      airlineAd: airline,
      flightN: flight, //The flight's name
      timestamp: Math.floor(Date.now() / 100000),
    };
    self.flightSuretyApp.methods
      .registerFlight(payload.airlineAd, payload.flightN, payload.timestamp)
      .send({ from: self.owner, gas: 999999 }, (error, result) => {
        callback(error, payload);
      });
  }

  fetchFlightStatus(flight, callback) {
    let self = this;
    let payload = {
      airline: this.owner,
      flight: flight,
      timestamp: Math.floor(Date.now() / 100000),
    };
    self.flightSuretyApp.methods
      .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
      .send({ from: self.owner, gas: 999999 }, (error, result) => {
        callback(error, payload);
      });
  }

  buy(flight, callback) {
    let self = this;
    let payload = {
      flight: flight,
    };
    self.flightSuretyData.methods.buy(payload.flight).send(
      {
        from: self.owner,
        value: this.web3.utils.toWei("1", "ether"),
      },
      (error, result) => {
        callback(error, payload);
      }
    );
  }

  pay(callback) {
    let self = this;

    self.flightSuretyData.methods.pay().send(
      {
        from: self.owner,
      },
      (error, result) => {
        callback(error, payload);
      }
    );
  }
}
