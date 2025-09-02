import { FunctionComponent } from "react";

interface FooterProps {
  text: string[];
}

const Footer: FunctionComponent<FooterProps> = (props) => {
  return (
    <div className="footer">
      {props.text.map((t) => {
        return (
          <div
            style={{
              fontSize: "8px",
              color: "grey",
              lineHeight: "20px",
            }}
          >
            {t}
          </div>
        );
      })}
    </div>
  );
};

export default Footer;
