import React, { useState } from "react";
import "./App.css";
import Header from "./components/Header";
import Footer from "./components/Footer";
import List from "./components/List";
import AddToList from "./components/AddToList";

export interface IState {
  books: {
    name: string;
    author: string;
    checkedOut: string;
    checkedOutBy?: string;
  }[];
}

function App() {
  const [books, setBooks] = useState<IState["books"]>([
    {
      name: "Hitchhiker's Guide",
      author: "Douglas Adams",
      checkedOut: "available",
      checkedOutBy: "",
    },
  ]);
  return (
    <div className="App">
      <Header />
      <AddToList books={books} setBooks={setBooks} />
      <List books={books} />
      <Footer />
    </div>
  );
}

export default App;
