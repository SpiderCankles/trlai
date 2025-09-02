import React, { FunctionComponent, ReactHTML, useState } from "react";
import { IState as Props } from "../App";

interface IProps {
  books: Props["books"];
  setBooks: React.Dispatch<React.SetStateAction<Props["books"]>>;
}

const AddToList: React.FC<IProps> = ({ books, setBooks }) => {
  const [input, setInput] = useState({
    name: "",
    author: "",
    checkedOut: "",
    checkedOutBy: "",
  });

  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>
  ) => {
    setInput({
      ...input,
      [e.target.name]: e.target.value,
    });
  };
  const handleClick = () => {
    if (!input.author || !input.name || !input.checkedOut) {
      return;
    }

    setBooks([
      ...books,
      {
        name: input.name,
        author: input.author,
        checkedOut: input.checkedOut,
        checkedOutBy: input.checkedOutBy,
      },
    ]);

    setInput({
      name: "",
      author: "",
      checkedOut: "",
      checkedOutBy: "",
    });
  };

  return (
    <div className="AddToList">
      <input
        type="text"
        placeholder="Book Name"
        className="AddToList-input"
        value={input.name}
        onChange={handleChange}
        name="name"
      />
      <input
        type="text"
        placeholder="Author Name"
        className="AddToList-input"
        value={input.author}
        onChange={handleChange}
        name="author"
      />
      <select
        value={input.checkedOut}
        placeholder="Am I available?"
        className="AddToList-input"
        onChange={handleChange}
        name="checkedOut"
      >
        <option value="Available">Checked Out</option>
        <option value="Checked Out">Available</option>
      </select>
      <input
        type="text"
        placeholder="Checked Out by"
        className="AddToList-input"
        value={input.checkedOutBy}
        onChange={handleChange}
        name="checkedOutBy"
      />
      <button className="AddToList-btn" onClick={handleClick}>
        Add To List
      </button>
    </div>
  );
};

export default AddToList;
