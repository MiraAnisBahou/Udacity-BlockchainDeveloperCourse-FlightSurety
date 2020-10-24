import DOM from "./dom";
import Contract from "./contract";
import "./flightsurety.css";

(async () => {
  let result = null;

  let contract = new Contract("localhost", () => {
    // Read transaction
    contract.isOperational((error, result) => {
      console.log(error, result);
      display("Operational Status", "Check if contract is operational", [
        { label: "Operational Status", error: error, value: result },
      ]);
    });

    DOM.elid("register-airline").addEventListener("click", () => {
      let airlineAddress = DOM.elid("airline-address").value;
      let airlineName = DOM.elid("airline-name").value;
      // Write transaction
      contract.registerAirline(airlineAddress, airlineName, (error, result) => {
        display("Airline", "Register Airline", [
          {
            label: "Airline Registered",
            error: error,
            value: result.nameOfAirline,
          },
        ]);
      });
    });

    DOM.elid("fund-airline").addEventListener("click", () => {
      let airlineAddress = DOM.elid("airline-that-funded").value;
      // Write transaction
      contract.fund(airlineAddress, (error, result) => {
        display("Airline", "Airline Funded", [
          {
            label: "Airline Paid Funds",
            error: error,
            value: result.airline,
          },
        ]);
      });
    });

    DOM.elid("register-flight").addEventListener("click", () => {
      let airlineAddress = DOM.elid("airline-address2").value;
      let flightname = DOM.elid("flight-name").value;
      let timestamp = Math.floor(Date.now() / 100000);
      // Write transaction
      contract.registerFlight(
        airlineAddress,
        flightname,
        timestamp,
        (error, result) => {
          display("Flight", "Flight registered", [
            {
              label: "Flight Registered",
              error: error,
              value: result.flightN,
            },
          ]);
        }
      );
    });

    DOM.elid("buy-flight-insurance").addEventListener("click", () => {
      let flightAddress = DOM.elid("buy-flight-insurance-value").value;
      // Write transaction
      contract.buy(flightAddress, (error, result) => {
        display("Insurance", "Insurance is bought", [
          {
            label: "Insurance bought",
            error: error,
            value: result.flight,
          },
        ]);
      });
    });

    // User-submitted transaction
    DOM.elid("submit-oracle").addEventListener("click", () => {
      let flight = DOM.elid("flight-number").value;
      // Write transaction
      contract.fetchFlightStatus(flight, (error, result) => {
        display("Oracles", "Trigger oracles", [
          {
            label: "Fetch Flight Status",
            error: error,
            value: result.flight + " " + result.timestamp,
          },
        ]);
      });
    });

    DOM.elid("withdraw-credit").addEventListener("click", () => {
      // Write transaction
      contract.pay((error, result) => {
        display("Credit Withdrawn", "Credit is Withdrawn", [
          {
            label: "Credit Withdrawn",
            error: error,
            value: result,
          },
        ]);
      });
    });
  });
})();

function display(title, description, results) {
  let displayDiv = DOM.elid("display-wrapper");
  let section = DOM.section();
  section.appendChild(DOM.h2(title));
  section.appendChild(DOM.h5(description));
  results.map((result) => {
    let row = section.appendChild(DOM.div({ className: "row" }));
    row.appendChild(DOM.div({ className: "col-sm-4 field" }, result.label));
    row.appendChild(
      DOM.div(
        { className: "col-sm-8 field-value" },
        result.error ? String(result.error) : String(result.value)
      )
    );
    section.appendChild(row);
  });
  displayDiv.append(section);
}
