import FlightSuretyApp from "../../build/contracts/FlightSuretyApp.json";
import Config from "./config.json";
import Web3 from "web3";
import express from "express";

let config = Config["localhost"];
let web3 = new Web3(
  new Web3.providers.WebsocketProvider(config.url.replace("http", "ws"))
);
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(
  FlightSuretyApp.abi,
  config.appAddress
);

let statusCodes = [0, 10, 20, 30, 40, 50];
let registerationFee = web3.utils.toWei("1", "ether");

let oracleCount = 20;
let oracleInfo = [];
// = { oracleNumber: 0, address: 0, indexes: 0 };

let accounts = web3.eth.getAccounts();

//web3.eth.getAccounts().then(accounts => {
for (let a = 0; a < oracleCount; a++) {
  flightSuretyApp.methods
    .registerOracle()
    .send({ from: accounts[a], value: registerationFee });
  let result = flightSuretyApp.methods
    .getMyIndexes()
    .send({ from: accounts[a] });
  oracleInfo[a] = {
    oracleNumber: a + 1,
    address: accounts[a],
    indexes: result,
  };
}
// if (error) {
//   console.log(error);
// }
//});

let num = 5;
let oracleStatusCode = statusCodes[Math.floor(Math.random() + num)];

flightSuretyApp.events.OracleRequest(
  {
    fromBlock: 0,
  },
  function (error, event) {
    let index = event.returnValues.index;
    let airline = event.returnValues.airline;
    let flight = event.returnValues.flight;
    let timestamp = event.returnValues.flight;
    let statusCode = oracleStatusCode;

    for (let b = 0; b < accounts.length; b++) {
      for (let c = 0; c < 3; c++) {
        //For indexes
        if (oracleInfo[b].indexes == index[c]) {
          flightSuretyApp.methods
            .submitOracleResponse(index, airline, flight, timestamp, statusCode)
            .send({ from: oracleInfo[b].address });
          break;
        }
      }
    }
    if (error) console.log(error);
    console.log(event);
  }
);

const app = express();
app.get("/api", (req, res) => {
  res.send({
    message: "An API for use with your Dapp!",
  });
});

export default app;
