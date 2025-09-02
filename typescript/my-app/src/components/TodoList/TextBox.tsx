import { FunctionComponent } from "react";

interface TextBoxProps {
  //   name: string;
  placeholder: string;
  value: string;
  onChange: (val: string) => void;
}

const TextBox: FunctionComponent<TextBoxProps> = ({
  placeholder,
  value,
  onChange,
}) => {
  return (
    <div className="text-box">
      <input
        value={value}
        onChange={({ target: { value } }) => onChange(value)}
      ></input>
    </div>
  );
};

export default TextBox;
