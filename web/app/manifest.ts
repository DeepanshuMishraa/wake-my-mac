import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Wake My Mac",
    short_name: "Wake My Mac",
    description: "Keep your Mac awake for long-running work.",
    start_url: "/",
    display: "standalone",
    background_color: "#fff1df",
    theme_color: "#d9ff54",
    lang: "en",
  };
}
