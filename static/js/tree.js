const makeNodes = (t) => {
    return [t, ...t.children].map(n => ({ id: n._id, label: n.book.title, shape: 'image', image: n.book.cover, tree: n }));
}

const drawTree = (t) => {
    const treeContainer = document.getElementById('tree');
    const nodes = Object.values(makeNodes(t));
    const edges = t.edges;
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
            borderWidth:0,
            size:42,
            shape: 'image',
            color: {
                border: '#222'
            },
            font: {
                color: '#111',
                size: 16,
                strokeWidth: 1,
                strokeColor: '#222'
            }
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
                sortMethod: "directed",
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
