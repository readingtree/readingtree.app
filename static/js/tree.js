const makeNodes = (t, edges) => {
    const tos = edges.map(e => e.to);
    const froms = edges.map(e => e.from);
    const inverseRoots = froms.filter(x => !tos.includes(x));

    return [t, ...t.children].map(n => {
        // TODO: Also if we've read this already.
        let border;
        if (inverseRoots.includes(n._id)) {
            border = '#0f0';
        } else {
            border = '#f00';
        }
        return {
            id: n._id,
            _label: n.book.title,
            shape: 'image',
            image: n.book.cover,
            tree: n,
            color: {
                border
            }
        };
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
            dragView: true
        },
        physics: {
            enabled: true,
            forceAtlas2Based: {
                springLength: 1000,
                avoidOverlap: 0.3
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
                color: '#CCC'
            },
            arrows: "to",
            width: 2,
            length: 300
        },
        layout: {
            randomSeed: 5
        },
        interaction: {
            hover: true
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

    network.on('click', properties => {
        const ids = properties.nodes;
        const clickedNode = nodes.get(ids)[0];

        if (!clickedNode) return;

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
