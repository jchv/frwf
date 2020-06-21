local stateman = {}

function stateman.load(first)
  stateman.scene = first
  stateman.scene.load()
end

function stateman.next(next)
  stateman.scene = next
  stateman.scene.load()
end

function stateman.update(dt)
  stateman.scene.update(dt)
end

function stateman.draw()
  stateman.scene.draw()
end

return stateman
