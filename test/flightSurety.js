var Test = require("../config/testConfig.js");
var BigNumber = require("bignumber.js");
//var web3 = require("web3.js");

contract("Flight Surety Tests", async (accounts) => {
  var config;
  const paidAirlineFunds = web3.utils.toWei("10", "ether");
  before("setup contract", async () => {
    config = await Test.Config(accounts);
    const STATUS_CODE_LATE_AIRLINE = 20;
    //await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {
    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");
  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {
    // Ensure that access is denied for non-Contract Owner account
    let accessDenied = false;
    try {
      await config.flightSuretyData.setOperatingStatus(false, {
        from: config.testAddresses[2],
      });
    } catch (e) {
      accessDenied = true;
    }
    assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {
    // Ensure that access is allowed for Contract Owner account
    let accessDenied = false;
    try {
      await config.flightSuretyData.setOperatingStatus(false);
    } catch (e) {
      accessDenied = true;
    }
    assert.equal(
      accessDenied,
      false,
      "Access not restricted to Contract Owner"
    );
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {
    await config.flightSuretyData.setOperatingStatus(false);

    let reverted = false;
    try {
      await config.flightSurety.setTestingMode(true);
    } catch (e) {
      reverted = true;
    }
    assert.equal(reverted, true, "Access not blocked for requireIsOperational");

    // Set it back for other tests to work
    await config.flightSuretyData.setOperatingStatus(true);
  });

  it("With 50% consensus, the 5th airline can be registered!, the airline must be registered and funded before registering other airlines", async () => {
    // ARRANGE
    let newAirline = accounts[8];
    let newName = "Airline_D";
    let newAirline2 = accounts[9];
    let newName2 = "Airline_E";
    let newAirline3 = accounts[10];
    let newName3 = "Airline_F";
    let newAirline4 = accounts[11];
    let newName4 = "Airline_G";

    // ACT
    await config.flightSuretyApp.fund(accounts[0], {
      from: accounts[0],
      value: paidAirlineFunds,
    });
    await config.flightSuretyApp.registerAirline(newAirline, newName, {
      from: accounts[0],
    });

    await config.flightSuretyApp.fund(newAirline, {
      from: newAirline,
      value: paidAirlineFunds,
    });
    await config.flightSuretyApp.registerAirline(newAirline2, newName2, {
      from: newAirline,
    });
    await config.flightSuretyApp.fund(newAirline2, {
      from: newAirline2,
      value: paidAirlineFunds,
    });
    await config.flightSuretyApp.registerAirline(newAirline3, newName3, {
      from: accounts[0],
    });
    await config.flightSuretyApp.fund(newAirline3, {
      from: newAirline3,
      value: paidAirlineFunds,
    });
    await config.flightSuretyApp.registerAirline(newAirline4, newName4, {
      from: newAirline2,
    });
    //Uncomment this if you want to register the 5th airline (since it needs 50% consensus)
    //Then change the value in assert to true, since it becomes registered.
    // await config.flightSuretyApp.registerAirline(newAirline4, newName4, {
    //   from: newAirline,
    // });

    let result = await config.flightSuretyData.returnRegistrationStatus.call({
      from: newAirline4,
    });

    // ASSERT
    assert.equal(
      result,
      false,
      "50% consensus needs to be achieved in order to register the 5th airline."
    );
  });

  it(`Flight can only be registered if airline is registered!`, async function () {
    let newAirline = accounts[12];
    let flightName = "Flight_A";
    let time = 120304; //Hours, minutes, seconds.
    let flightAd = accounts[13];

    // ACT
    try {
      await config.flightSuretyApp.registerFlight(
        newAirline,
        flightName,
        time,
        { from: flightAd }
      );
    } catch (e) {
      console.log(e);
    }

    let result = await config.flightSuretyApp.retrieveRegisteredFlight.call({
      from: flightAd,
    });

    // ASSERT
    assert.equal(result, 0, "Airline needs to be registered!");
  });

  it(`Requestor can buy flight insurance and can retrieve money if plane had problems`, async function () {
    let person = accounts[14];
    let flightAd = accounts[15];
    let flight = "ND1309"; // Course number
    let timestamp = Math.floor(Date.now() / 100000);

    // ACT
    await config.flightSuretyApp.registerFlight(
      accounts[0],
      flight,
      timestamp,
      { from: flightAd }
    );
    await config.flightSuretyData.buy(flightAd, {
      from: person,
      value: web3.utils.toWei("1", "ether"),
    });

    await config.flightSuretyData.creditInsurees(person);

    let result = Number(
      await config.flightSuretyData.amountAPersonHas.call({
        from: person,
      })
    );
    // ASSERT
    assert.equal(
      result,
      web3.utils.toWei("1.5", "ether"),
      "Requestor didn't get money back!"
    );
  });
});
