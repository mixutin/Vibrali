document.querySelectorAll("[data-copy]").forEach((button) => {
  button.addEventListener("click", async () => {
    const target = document.getElementById(button.dataset.copy);
    try {
      await navigator.clipboard.writeText(target.textContent.trim());
      const old = button.textContent;
      button.textContent = "Copied";
      setTimeout(() => { button.textContent = old; }, 1400);
    } catch {
      button.textContent = "Select + copy";
    }
  });
});

const api = "https://api.github.com/repos/mixutin/Vibrali/releases/latest";

fetch(api, { headers: { Accept: "application/vnd.github+json" } })
  .then((response) => {
    if (!response.ok) throw new Error("No release");
    return response.json();
  })
  .then((release) => {
    document.getElementById("release-version").textContent = release.tag_name;
    document.getElementById("release-date").textContent =
      new Date(release.published_at).toLocaleDateString(undefined, {
        year: "numeric", month: "short", day: "numeric"
      });

    document.getElementById("release-link").href = release.html_url;

    const vm = release.assets.find((asset) =>
      asset.name === "vibrali-qemu-amd64.qcow2.zst"
    );
    document.getElementById("vm-download").href = vm ? vm.browser_download_url : release.html_url;
  })
  .catch(() => {
    document.getElementById("release-date").textContent = "first release coming soon";
  });
