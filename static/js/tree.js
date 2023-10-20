const makeNodes = (t, edges) => {
    const tos = edges.map(e => e.to);
    const froms = edges.map(e => e.from);
    const inverseRoots = froms.filter(x => !tos.includes(x));

    return [t, ...t.children].map(n => {
        // TODO: Also if we've read this already.
        const treeNode = {
            id: n._id,
            _label: n.book.title,
            shape: 'image',
            image: n.book.cover,
            tree: n,
            color: {}
        };
        if (inverseRoots.includes(n._id)) {
            treeNode.color.border = '#0f0';
            treeNode.unlocked = true;
        } else {
            treeNode.color.border = '#f00';
            treeNode.unlocked = false;
        }

        return treeNode;
    });
}

const drawTree = (t) => {
    const treeContainer = document.getElementById('tree');
    const edges = new vis.DataSet(t.edges);
    const nodes = new vis.DataSet(Object.values(makeNodes(t, edges)));
    const data = {
        nodes,
        edges
    };

    const options = {
        interaction: {
            dragNodes: false,
            dragView: true,
            hover: true
        },
        physics: {
            enabled: true,
            stabilization: {
                enabled: true,
                iterations: 100
            },
            forceAtlas2Based: {
                springLength: 1000,
                avoidOverlap: 1
            },
            solver: 'forceAtlas2Based'
        },
        nodes: {
            size: 33,
            shape: 'image',
            font: {
                color: '#111',
                size: 16,
                strokeWidth: 1,
                strokeColor: '#222'
            },
            shapeProperties: {
                useBorderWithImage: true,
            },
        },
        edges: {
            color: {
                color: '#CCC',
                hover: '#CCC'
            },
            arrows: "to",
            width: 2,
            length: 300,
            hoverWidth: 0
        },
        layout: {
            randomSeed: 5
        }
    };

    const network = new vis.Network(treeContainer, data, options);

    network.on('hoverNode', function (params) {
        console.log("foo");
        network.canvas.body.container.style.cursor = 'pointer'
    });

    network.on('blurNode', function (params) {
        console.log("foo123");
        network.canvas.body.container.style.cursor = 'default'
    });

    network.on('selectNode', clickedObject => {
        const clickedNode = nodes.get(clickedObject.nodes[0]);
        if (!clickedNode) return;

        if (clickedNode.unlocked)
            nodes.update({ ...clickedNode, label: clickedNode._label });

        console.log(clickedNode);
    });
}

const getTree = async (treeId = window.location.href.split(/\//).pop()) => {
    try {
        const response = await fetch(`/api/trees/${treeId}`);
        if (response.status === 404) {
            throw Error("Tree not found :(");
        }

        drawTree(await response.json());
    } catch (e) {
        console.error(e);
    }
}

getTree();
