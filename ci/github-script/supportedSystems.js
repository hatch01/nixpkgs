module.exports = async ({ github, context, targetSha }) => {
  const { content, encoding } = (
    await github.rest.repos.getContent({
      ...context.repo,
      path: 'pkgs/top-level/release-supported-systems.json',
      ref: targetSha,
    })
  ).data

  const systems = JSON.parse(Buffer.from(content, encoding).toString())

  const matrixEntries = systems.map(system => ({ system }))

  // Add a dedicated cross-eval row to evaluate on x86_64-linux using
  // pkgsCross.aarch64-multiplatform.
  if (systems.includes('x86_64-linux')) {
    matrixEntries.push({
      system: 'x86_64-linux',
      evalSet: 'pkgsCross.aarch64-multiplatform',
    })
  }

  return JSON.stringify(matrixEntries)
}