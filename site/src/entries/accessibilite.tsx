import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { Accessibilite } from "../pages/Accessibilite.tsx";
import "../styles.css";

const container = document.getElementById("root");
if (!container) throw new Error("Élément #root introuvable");

createRoot(container).render(
  <StrictMode>
    <Accessibilite />
  </StrictMode>,
);
