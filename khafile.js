let project = new Project('Sample');

project.addLibrary('assimp-kha');

project.addAssets('Assets/**');
project.addSources('Sources');
project.addShaders('Shaders/**');

resolve(project);
