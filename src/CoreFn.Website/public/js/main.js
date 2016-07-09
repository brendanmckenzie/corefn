import React, { Component } from 'react'
import ReactDOM from 'react-dom'
import 'whatwg-fetch';

class Demo extends Component {
  constructor () {
    super()

    this.state = { msg: null }
  }

  handleClick () {
    fetch('/demo/Functions/Example.HelloWorld')
      .then(res => res.text())
      .then(res => this.setState({ msg: res }))
  }

  render () {
    return <div>
      <button className='button' onClick={this.handleClick.bind(this)}>Cilck me</button>
      <div>Response: {this.state.msg}</div>
    </div>
  }
}

const init = () => {
  const elem = document.getElementById('demo')
  ReactDOM.render(<Demo />, elem)
}

init()
