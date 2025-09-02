import "./App.css";

import Header from "./components/Header";
import Footer from "./components/Footer";
import TodoList from "./components/TodoList/TodoList";

const App = () => {
  return (
    <div className="App">
      <Header text="todos" />
      <TodoList />
      <Footer text={["Double Click Bitch", "the other way", "By James"]} />
    </div>
  );
};

export default App;
