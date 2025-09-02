import React, { FunctionComponent } from "react";
import { IState as IProps } from "../App";

const List: FunctionComponent<IProps> = ({ books }) => {
  const renderList = (): JSX.Element[] => {
    return books.map((book) => {
      return (
        <li className="List">
          <div className="List-Header">
            <h2>{book.name}</h2>
          </div>
          <p>{book.author}</p>
          <p>{book.checkedOut}</p>
          <p>{book.checkedOutBy}</p>
        </li>
      );
    });
  };
  return <ul>{renderList()}</ul>;
};

export default List;
