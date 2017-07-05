const React = require('react');
const ReactDOM = require('react-dom');

import RaisedButton from 'material-ui/RaisedButton';
import MuiThemeProvider from 'material-ui/styles/MuiThemeProvider';

import 'whatwg-fetch';

class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      count: 0
    }
  }

  componentDidMount() {
    fetch('/counters/anticipay', {method: 'GET'})
      .then((response) => response.json())
      .then((body) => {
        this.setState({
          count: body.counter
        });
      });
  }

  up(e) {
    fetch('/counters/anticipay/up', {method: 'POST'}, {up: true})
      .then((response) => response.json())
      .then((body) => {
        this.setState({
          count: body.counter
        });
      });
  }

  down(e) {
    fetch('/counters/anticipay/down', {method: 'POST'}, {down: true})
      .then((response) => response.json())
      .then((body) => {
        this.setState({
          count: body.counter
        });
      });
  }

  render() {
    return (
      <MuiThemeProvider>
        <div>
          <RaisedButton onClick={this.down.bind(this)} primary={true} label="Down" />
          <span className="display-3" style={{padding: "10px"}}>{this.state.count}</span>
          <RaisedButton onClick={this.up.bind(this)} primary={true} label="Up" />
        </div>
      </MuiThemeProvider>
    );
  }
}

ReactDOM.render(
  <App/>,
  document.getElementById('application-container')
);
