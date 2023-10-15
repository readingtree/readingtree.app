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
            label: n.book.title,
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
    const edges = t.edges;
    const nodes = Object.values(makeNodes(t, edges));
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
            hierarchicalRepulsion: {
                centralGravity: 0.0,
                springLength: 250,
                springConstant: 0.01,
                nodeDistance: 500
            },
            solver: 'hierarchicalRepulsion',
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
            hierarchical: {
                direction: "UD",
                nodeSpacing: 400,
                treeSpacing: 600
            }
        }
    };

    const network = new vis.Network(treeContainer, data, options);
    // Network configurations
    network.on("stabilizationIterationsDone", function(){
        network.setOptions( { physics: false } );
    });

    network.on("hoverNode", function (params) {
        network.canvas.body.container.style.cursor = 'pointer'
    });

    network.on("blurNode", function (params) {
        network.canvas.body.container.style.cursor = 'default'
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
