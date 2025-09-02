import { FunctionComponent } from "react";

interface HeaderProps {
    text: string;
}

const Header: FunctionComponent<HeaderProps> = (props) => {
    return <div style={{
        color: 'rgba(175, 47, 47, 0.15)',
        fontWeight: '100',
        textAlign: 'center',
        fontSize: '100px'
    }}>{props.text}</div>;
};

export default Header; 