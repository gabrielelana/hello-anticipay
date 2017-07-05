const React = require('react');
const ReactDOM = require('react-dom');

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
      <div>
        <button onClick={this.down.bind(this)}>Down</button>
        <h1>{this.state.count}</h1>
        <button onClick={this.up.bind(this)}>Up</button>
      </div>
    )
  }
}

ReactDOM.render(
  <App/>,
  document.getElementById('application-container')
);
