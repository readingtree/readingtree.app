const showModal = (t, network) => {
    const rawElem = document.getElementById('book-modal');
    rawElem.addEventListener('hide.bs.modal', _ => {
        rawElem.querySelector('.modal-title').innerHTML = "";
        rawElem.querySelector('.modal-body').innerHTML = "";
        network.selectNodes([]); // Hack to deselect the node.
    });

    const modalElem = new bootstrap.Modal(rawElem);

    const generateInnerHtml = (root) => {
        const book = t.tree.book;
        const image = document.createElement('img');
        image.src = t['image'];
        image.style = 'width: 220px; height: 309px; display: block; margin-left: auto; margin-right: auto;'
        image.classList.add('my-3');
        root.appendChild(image);

        for (const key of ['Author', 'ISBN']) {
            const div = document.createElement('div');
            const label = document.createElement('strong');
            label.innerText = key + ': ';
            div.appendChild(label);
            div.appendChild(document.createTextNode(book[key.toLowerCase()]));
            root.appendChild(div);
        }
    };

    const headerElem = rawElem.querySelector('.modal-title');
    headerElem.innerText = t._label;

    const bodyElem = rawElem.querySelector('.modal-body');
    generateInnerHtml(bodyElem);

    modalElem.toggle();
};

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
            borderWidth: 3,
            color: {},
            interaction: {}
        };
        if (inverseRoots.includes(n._id)) {
            treeNode.color.border = '#D1D1D1';
            treeNode.unlocked = true;
        } else {
            treeNode.color.border = '#FF6961';
            treeNode.interaction.hover = false;
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
            stabilization: {
                enabled: true,
                iterations: 100
            },
            solver: 'forceAtlas2Based',
            maxVelocity: 0
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
        const node = nodes.get(params.node);
        if (node && node.unlocked) {
            network.canvas.body.container.style.cursor = 'pointer';
        }
    });

    network.on('blurNode', function (params) {
        network.canvas.body.container.style.cursor = 'default';
    });

    network.on('selectNode', clickedObject => {
        const clickedNode = nodes.get(clickedObject.nodes[0]);
        if (!clickedNode) return;

        if (clickedNode.unlocked) {
            showModal(clickedNode, network);
        }

    });

    network.on('click', ({ nodes, edges }) => {
        if (nodes.length == 0 && edges.length > 0) {
            network.setSelection({
                nodes: [],
                edges: []
            });
        }
    });

    network.on('deselectNode', clickedObject => {
        const clickedNode = nodes.get(clickedObject.previousSelection.nodes[0].id);

        if (!clickedNode) return;
        nodes.update({ ...clickedNode, label: "" });
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
        document.querySelector('#app').innerHTML = '';
        document.querySelector('#app')
            .appendChild(document.createTextNode(`An unknown error occurred: ${e.toString()}.`));
        console.error(e);
    }
}

getTree();
