import { FunctionComponent, useState, useRef } from "react";
import TextBox from "./TextBox";
import TodoFooter from "./TodoFooter";
import Todo, { TodoData } from "./Todo";

const TodoList: FunctionComponent = () => {
  const [todoDataList, setTodos] = useState<TodoData[]>([]);

  const [val, setVal] = useState("");
  const inputRef = useRef(null);

  return (
    <div className="todo-list">
      <TextBox
        placeholder="Just a hold"
        value={val}
        onChange={setVal} /*ref={inputRef}*/
      />

      {todoDataList.map((todoData) => {
        return <Todo todoData={todoData} />;
      })}

      <TodoFooter />
    </div>
  );
};

export default TodoList;
