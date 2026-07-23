import type { MetadataRoute } from "next";
import { siteUrl } from "./site";

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    { url: `${siteUrl}/`, lastModified: new Date("2026-07-24") },
    { url: `${siteUrl}/keep-mac-awake`, lastModified: new Date("2026-07-24") },
    { url: `${siteUrl}/keepingyouawake-alternative`, lastModified: new Date("2026-07-24") },
    { url: `${siteUrl}/privacy`, lastModified: new Date("2026-07-24") },
  ];
}
