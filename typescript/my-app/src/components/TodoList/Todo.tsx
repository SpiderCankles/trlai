import { FunctionComponent } from "react";

export interface TodoData {
  text: string;
  checked?: boolean;
}

interface TodoProps {
  todoData: TodoData;
}

const Todo: FunctionComponent<TodoProps> = (props) => {
  return <div className="todo"></div>;
};

export default Todo;
