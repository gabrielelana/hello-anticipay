const React = require('react');
const ReactDOM = require('react-dom');

import RaisedButton from 'material-ui/RaisedButton';
import MuiThemeProvider from 'material-ui/styles/MuiThemeProvider';

class App extends React.Component {
  constructor(props) {
    super();
    this.state = {
      count: 0
    }
  }

  up(e) {
    this.setState({
      count: this.state.count + 1
    });
  }

  down(e) {
    this.setState({
      count: this.state.count - 1
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
