QUnit.test("form elements check", assert => {
  $('#forms').append('<hr><h1>form elements check 1</h1><form id="form1"></form>')
  var el = $('#form1')
  new App.ControllerForm({
    el:        el,
    model:     {
      "configure_attributes": [
        {
          "name": "tree_select",
          "display": "tree_select",
          "tag": "tree_select",
          "null": true,
          "translate": true,
          "options": [
            {
              "value": "aa",
              "name": "yes",
              "children": [
                  {
                    "value": "aa::aaa",
                    "name": "yes1",
                  },
                  {
                    "value": "aa::aab",
                    "name": "yes2",
                  },
                  {
                    "value": "aa::aac",
                    "name": "yes3",
                  },
              ]
            },
            {
              "value": "bb",
              "name": "bb (comment)",
              "children": [
                  {
                    "value": "bb::bba",
                    "name": "yes11",
                  },
                  {
                    "value": "bb::bbb",
                    "name": "yes22",
                  },
                  {
                    "value": "bb::bbc",
                    "name": "yes33",
                  },
              ]
            },
          ],
        }
      ]
    },
    autofocus: true
  });
  assert.equal(el.find('[name="tree_select"]').val(), '', 'check tree_select value');
  assert.equal(el.find('[name="tree_select"]').closest('.searchableSelect').find('.js-input').val(), '', 'check tree_select .js-input value');
  var params = App.ControllerForm.params(el)
  var test_params = {
    tree_select: ''
  }
  assert.deepEqual(params, test_params, 'form param check')

  $('#forms').append('<hr><h1>form elements check 2</h1><form id="form2"></form>')
  var el = $('#form2')
  new App.ControllerForm({
    el:        el,
    model:     {
      "configure_attributes": [
        {
          "name": "tree_select",
          "display": "tree_select",
          "tag": "tree_select",
          "null": true,
          "translate": true,
          "value": "aa",
          "options": [
            {
              "value": "aa",
              "name": "yes",
              "children": [
                  {
                    "value": "aa::aaa",
                    "name": "yes1",
                  },
                  {
                    "value": "aa::aab",
                    "name": "yes2",
                  },
                  {
                    "value": "aa::aac",
                    "name": "yes3",
                  },
              ]
            },
            {
              "value": "bb",
              "name": "bb (comment)",
              "children": [
                  {
                    "value": "bb::bba",
                    "name": "yes11",
                  },
                  {
                    "value": "bb::bbb",
                    "name": "yes22",
                  },
                  {
                    "value": "bb::bbc",
                    "name": "yes33",
                  },
              ]
            },
          ],
        }
      ]
    },
    autofocus: true
  });

  assert.equal(el.find('[name="tree_select"]').val(), 'aa', 'check tree_select value');
  assert.equal(el.find('[name="tree_select"]').closest('.searchableSelect').find('.js-input').val(), 'yes', 'check tree_select .js-input value');
  var params = App.ControllerForm.params(el)
  var test_params = {
    tree_select: 'aa'
  }
  assert.deepEqual(params, test_params, 'form param check')

  $('#forms').append('<hr><h1>form elements check 3</h1><form id="form3"></form>')
  var el = $('#form3')
  new App.ControllerForm({
    el:        el,
    model:     {
      "configure_attributes": [
        {
          "name": "tree_select",
          "display": "tree_select",
          "tag": "tree_select",
          "null": true,
          "translate": true,
          "value": "aa::aab",
          "options": [
            {
              "value": "aa",
              "name": "yes",
              "children": [
                  {
                    "value": "aa::aaa",
                    "name": "yes1",
                  },
                  {
                    "value": "aa::aab",
                    "name": "yes2",
                  },
                  {
                    "value": "aa::aac",
                    "name": "yes3",
                  },
              ]
            },
            {
              "value": "bb",
              "name": "bb (comment)",
              "children": [
                  {
                    "value": "bb::bba",
                    "name": "yes11",
                  },
                  {
                    "value": "bb::bbb",
                    "name": "yes22",
                  },
                  {
                    "value": "bb::bbc",
                    "name": "yes33",
                  },
              ]
            },
          ],
        }
      ]
    },
    autofocus: true
  });
  assert.equal(el.find('[name="tree_select"]').val(), 'aa::aab', 'check tree_select value');
  assert.equal(el.find('[name="tree_select"]').closest('.searchableSelect').find('.js-input').val(), 'yes2', 'check tree_select .js-input value');
  assert.equal(el.find('[name="tree_select"]').closest('.searchableSelect').find('.js-input').attr('title'), 'yes › yes2', 'check tree_select .js-input tooltip');
  var params = App.ControllerForm.params(el)
  var test_params = {
    tree_select: 'aa::aab'
  }
  assert.deepEqual(params, test_params, 'form param check')

  $('#forms').append('<hr><h1>form elements check 4</h1><form id="form4"></form>')
  var el = $('#form4')
  new App.ControllerForm({
    el:        el,
    model:     {
      "configure_attributes": [
        {
          "name": "tree_select_search",
          "display": "tree_select_search",
          "tag": "tree_select_search",
          "null": true,
          "translate": true,
          "multiple": true,
          "value": ['aa::aab', 'bb', 'aa::aac::33'],
          "options": [
            {
              "value": "aa",
              "name": "yes",
              "children": [
                  {
                    "value": "aa::aaa",
                    "name": "yes1",
                  },
                  {
                    "value": "aa::aab",
                    "name": "yes2",
                  },
                  {
                    "value": "aa::aac",
                    "name": "yes3",
                    "children": [
                        {
                          "value": "aa::aaa::11",
                          "name": "11",
                        },
                        {
                          "value": "aa::aa1::22",
                          "name": "22",
                        },
                        {
                          "value": "aa::aac::33",
                          "name": "33",
                        },
                    ]
                  },
              ]
            },
            {
              "value": "bb",
              "name": "bb (comment)",
              "children": [
                  {
                    "value": "bb::bba",
                    "name": "yes11",
                  },
                  {
                    "value": "bb::bbb",
                    "name": "yes22",
                  },
                  {
                    "value": "bb::bbc",
                    "name": "yes33",
                  },
              ]
            },
          ],
        }
      ]
    },
    autofocus: true
  });
  var params = App.ControllerForm.params(el)
  var test_params = {
    tree_select_search: ['aa::aab', 'bb', 'aa::aac::33'],
    tree_select_search_completion: ""
  }
  assert.deepEqual(params, test_params, 'form param check')

  $('#forms').append('<hr><h1>form elements check / tree_select multiple / 3 selected</h1><form id="form6"></form>')
  var el = $('#form6')
  new App.ControllerForm({
    el:        el,
    model:     {
      "configure_attributes": [
        {
          "name": "tree_select",
          "display": "tree_select",
          "tag": "tree_select",
          "null": true,
          "multiple": true,
          "translate": true,
          "value": ['aa::aab', 'bb', 'aa::aac::33'],
          "options": [
            {
              "value": "aa",
              "name": "yes",
              "children": [
                  {
                    "value": "aa::aaa",
                    "name": "yes1",
                  },
                  {
                    "value": "aa::aab",
                    "name": "yes2",
                  },
                  {
                    "value": "aa::aac",
                    "name": "yes3",
                    "children": [
                        {
                          "value": "aa::aaa::11",
                          "name": "11",
                        },
                        {
                          "value": "aa::aa1::22",
                          "name": "22",
                        },
                        {
                          "value": "aa::aac::33",
                          "name": "33",
                        },
                    ]
                  },
              ]
            },
            {
              "value": "bb",
              "name": "bb (comment)",
              "children": [
                  {
                    "value": "bb::bba",
                    "name": "yes11",
                  },
                  {
                    "value": "bb::bbb",
                    "name": "yes22",
                  },
                  {
                    "value": "bb::bbc",
                    "name": "yes33",
                  },
              ]
            },
          ],
        }
      ]
    },
    autofocus: true
  });
  var params = App.ControllerForm.params(el)
  var test_params = {
    tree_select: ['aa::aab', 'bb', 'aa::aac::33'],
    tree_select_completion: "",
  }
  assert.deepEqual(params, test_params, 'form param check')

  $('#forms').append('<hr><h1>form elements check / tree_select multiple / 1 selected</h1><form id="form7"></form>')
  var el = $('#form7')
  new App.ControllerForm({
    el:        el,
    model:     {
      "configure_attributes": [
        {
          "name": "tree_select",
          "display": "tree_select",
          "tag": "tree_select",
          "null": true,
          "multiple": true,
          "translate": true,
          "value": ['aa::aab'],
          "options": [
            {
              "value": "aa",
              "name": "yes",
              "children": [
                  {
                    "value": "aa::aaa",
                    "name": "yes1",
                  },
                  {
                    "value": "aa::aab",
                    "name": "yes2",
                  },
                  {
                    "value": "aa::aac",
                    "name": "yes3",
                    "children": [
                        {
                          "value": "aa::aaa::11",
                          "name": "11",
                        },
                        {
                          "value": "aa::aa1::22",
                          "name": "22",
                        },
                        {
                          "value": "aa::aac::33",
                          "name": "33",
                        },
                    ]
                  },
              ]
            },
            {
              "value": "bb",
              "name": "bb (comment)",
              "children": [
                  {
                    "value": "bb::bba",
                    "name": "yes11",
                  },
                  {
                    "value": "bb::bbb",
                    "name": "yes22",
                  },
                  {
                    "value": "bb::bbc",
                    "name": "yes33",
                  },
              ]
            },
          ],
        }
      ]
    },
    autofocus: true
  });
  var params = App.ControllerForm.params(el)
  var test_params = {
    tree_select: ['aa::aab'],
    tree_select_completion: "",
  }
  assert.deepEqual(params, test_params, 'form param check')
});

QUnit.test("ui elements check", assert => {

  attribute =  {
    "name": "tree_select_search",
    "display": "tree_select_search",
    "tag": "tree_select_search",
    "null": true,
    "translate": true,
    "value": ['bb::bba', 'bb::bbb'],
    "multiple": true,
    "options": [
      {
        "value": "aa",
        "name": "yes",
        "children": [
            {
              "value": "aa::aaa",
              "name": "yes1",
            },
            {
              "value": "aa::aab",
              "name": "yes2",
            },
        ]
      },
      {
        "value": "bb",
        "name": "bb (comment)",
        "children": [
            {
              "value": "bb::bba",
              "name": "yes11",
            },
            {
              "value": "bb::bbb",
              "name": "yes22",
            },
        ]
      },
    ],
  };

  options = [
    {
      "value": "aa",
      "name": "yes",
      "children": [
          {
            "value": "aa::aaa",
            "name": "yes1",
          },
          {
            "value": "aa::aab",
            "name": "yes2",
          },
      ]
    },
    {
      "value": "bb",
      "name": "bb (comment)",
      "children": [
          {
            "value": "bb::bba",
            "name": "yes11",
          },
          {
            "value": "bb::bbb",
            "name": "yes22",
          },
      ]
    }
  ]

  element = App.UiElement.tree_select_search.render(attribute)
  assert.deepEqual(attribute.options, options, 'options tree_select_search')

  attribute.name = 'tree_select'
  attribute.display = 'tree_select'
  attribute.tag = 'tree_select'

  element = App.UiElement.tree_select.render(attribute)
  assert.deepEqual(attribute.options, options, 'options tree_select')
});

QUnit.test("searchable_select submenu and option list check", assert => {
  var done = assert.async()

  $('#forms').append('<hr><h1>form elements check 5</h1><form id="form5"></form>')
  var el = $('#form5')
  new App.ControllerForm({
    el:        el,
    model:     {
      "configure_attributes": [
        {
          "name": "tree_select",
          "display": "tree_select",
          "tag": "tree_select",
          "null": true,
          "translate": true,
          "value": "bb",
          "options": [
            {
              "value": "a\\a",
              "name": "a\\a",
              "children": [
                  {
                    "value": "a\\a::aaa",
                    "name": "aaa",
                  },
                  {
                    "value": "a\\a::aab",
                    "name": "aab",
                  },
                  {
                    "value": "a\\a::aac",
                    "name": "aac",
                  },
              ]
            },
            {
              "value": "bb",
              "name": "bb",
              "children": [
                  {
                    "value": "bb::bba",
                    "name": "bba",
                  },
                  {
                    "value": "bb::bbb",
                    "name": "bbb",
                  },
                  {
                    "value": "bb::bbc",
                    "name": "bbc",
                  },
              ]
            },
          ],
        }
      ]
    },
    autofocus: true
  });

  el.find("[name=\"tree_select\"].js-shadow + .js-input").trigger('click')
  el.find(".searchableSelect .js-optionsList [data-value=\"a\\\\a\"] .searchableSelect-option-arrow").mouseenter().trigger('click')
  el.find(".searchableSelect .js-optionsSubmenu [data-value=\"a\\\\a::aab\"] .searchableSelect-option-text").mouseenter().trigger('click')
  el.find("[name=\"tree_select\"].js-shadow + .js-input").trigger('click')

  var params = App.ControllerForm.params(el)
  var test_params = {
    tree_select: 'a\\a::aab'
  }

  var optionsSubmenu = el.find(".searchableSelect [data-parent-value=\"a\\\\a\"].js-optionsSubmenu")
  var optionsList = el.find(".searchableSelect .js-optionsList")

  setTimeout( () => {
    assert.deepEqual(params, test_params, 'form param check')
    assert.equal(optionsSubmenu.is('[hidden]'), false, 'options submenu menu not hidden')
    assert.equal(optionsList.is('[hidden]'), true, 'options list is hidden')

    done()
  }, 300)

});

QUnit.test("[Core Workflow] Remove option does not work with tree select node that has sub-options #4407", assert => {
  $('#forms').append('<hr><h1>Remove option does not work with tree select node that has sub-options #4407 form8</h1><form id="form8"></form>')
  var el = $('#form8')

  attribute = {
    "name": "ts4407",
    "display": "ts4407",
    "tag": "tree_select",
    "null": true,
    "nulloption": true,
    "translate": true,
    "filter": ["aa", "bb::aaa", "dd::aaa::bbb"],
    "options": [
      {
        "value": "aa",
        "name": "aa yes",
        "children": [
          {
            "value": "aa::aaa",
            "name": "aa yes1",
          },
          {
            "value": "aa::aab",
            "name": "aa yes2",
          },
        ]
      },
      {
        "value": "bb",
        "name": "bb yes",
        "children": [
          {
            "value": "bb::aaa",
            "name": "bb yes1",
          },
          {
            "value": "bb::aab",
            "name": "bb yes2",
          },
        ]
      },
      {
        "value": "cc",
        "name": "cc yes",
        "children": [
          {
            "value": "cc::aaa",
            "name": "cc yes1",
          },
          {
            "value": "cc::aab",
            "name": "cc yes2",
          },
        ]
      },
      {
        "value": "dd",
        "name": "dd yes",
        "children": [
          {
            "value": "dd::aaa",
            "name": "dd yes1",
            "children": [
              {
                "value": "dd::aaa::bbb",
                "name": "dd yes2",
              },
            ]
          },
        ]
      }
    ],
  }

  element = App.UiElement.tree_select.render(attribute)

  // children are removed
  assert.equal(false, element.find("[data-value='aa::aaa']").length > 0)

  // one child removed, one child allowed
  assert.equal(true, element.find("[data-value='bb::aaa'] span.searchableSelect-option-text:not(.is-inactive)").length > 0)
  assert.equal(false, element.find("[data-value='bb::aab']").length > 0)
  assert.equal(true, element.find("[data-value='bb'] span.searchableSelect-option-text.is-inactive").length > 0)

  // parent and childs removed
  assert.equal(false, element.find("[data-value='cc']").length > 0)
  assert.equal(false, element.find("[data-value='cc::aaa']").length > 0)
  assert.equal(false, element.find("[data-value='cc::aab']").length > 0)

  // level 3 child allowed
  assert.equal(true, element.find("[data-value='dd'] span.searchableSelect-option-text.is-inactive").length > 0)
  assert.equal(true, element.find("[data-value='dd::aaa'] span.searchableSelect-option-text.is-inactive").length > 0)
  assert.equal(true, element.find("[data-value='dd::aaa::bbb'] span.searchableSelect-option-text:not(.is-inactive)").length > 0)

  attribute.value = 'aa'
  element = App.UiElement.tree_select.render(attribute)
  assert.equal('aa yes', element.find(".js-input").val())

  attribute.value = 'aa::aaa'
  element = App.UiElement.tree_select.render(attribute)
  assert.equal('-', element.find(".js-input").val())

  attribute.tag = 'multi_tree_select'
  attribute.multiple = true

  attribute.value = ['aa']
  element = App.UiElement.tree_select.render(attribute)
  assert.equal(true, element.find(".token[data-value='aa']").length > 0)

  attribute.value = ['aa::aaa']
  element = App.UiElement.tree_select.render(attribute)
  assert.equal(false, element.find(".token[data-value='aa::aaa']").length > 0)

  el.append(element)
});

QUnit.test("[Core Workflow] Remove option does not work with tree select node that has relation #4407", assert => {
  $('#forms').append('<hr><h1>Remove option does not work with tree select node that has relation #4407 form8</h1><form id="form8_2"></form>')
  var el = $('#form8_2')

  App.Group.configure_attributes.push({ name: 'parent_id', display: 'Parent Group', tag: 'tree_select', relation: 'group' })

  App.Group.refresh([
    {
      id: 1,
      name: 'group 1',
      name_last: 'group 1',
    },
    {
      id: 2,
      name: 'group 1',
      name_last: 'group 2',
    },
  ])

  attribute = {
    "name": "ts4407_2",
    "display": "ts4407_2",
    "tag": "tree_select",
    "null": true,
    "nulloption": true,
    "translate": true,
    "relation": "Group",
    "filter": ['', '1'],
    "value": 1,
  }

  element = App.UiElement.tree_select.render(attribute)

  assert.equal(true, element.find("[data-value='1'] span.searchableSelect-option-text").length == 1)
  assert.equal(true, element.find("[data-value='2'] span.searchableSelect-option-text").length == 0)
  assert.equal(true, element.find(".js-input").val() == 'group 1')

  el.append(element)
});

QUnit.test("Escaping of values works just fine", assert => {
  $('#forms').append('<hr><h1>Escaping of values works just fine form9</h1><form id="form9"></form>')
  var el = $('#form9')

  attribute = {
    "name": "multi_tree_select",
    "display": "multi_tree_select",
    "tag": "multi_tree_select",
    "null": true,
    "nulloption": true,
    "translate": true,
    "multiple": true,
    "options": [
      {
        "value": "aa",
        "name": "aa yes",
        "children": [
          {
            "value": 'aa::aaa "test"',
            "name": "aa yes with quote",
          },
          {
            "value": "aa::aab",
            "name": "aa yes2",
          },
        ]
      },
    ],
  }

  attribute.value = ['aa::aaa "test"']
  element = App.UiElement.tree_select.render(attribute)

  escaped_selector = jQuery.escapeSelector('aa::aaa "test"')
  assert.equal(true, element.find(".token[data-value=" + escaped_selector + "]").length > 0)

  element.find('.js-remove').trigger('click')
  assert.equal(false, element.find(".token[data-value=" + escaped_selector + "]").length > 0)

  el.append(element)
});

QUnit.test("Missing selected groups for multi tree select relation in ticket zoom #5597", assert => {
  $('#forms').append('<hr><h1>Missing selected groups for multi tree select relation in ticket zoom #5597 form10</h1><form id="form10"></form>')
  var el = $('#form10')

  App.Group.configure_attributes.push({ name: 'parent_id', display: 'Parent Group', tag: 'tree_select', relation: 'Group' })

  App.Group.refresh([
    {
      id: 1,
      name: 'group 1',
      name_last: 'group 1',
      active: true,
    },
    {
      id: 2,
      name: 'group 1 > group 2',
      name_last: 'group 2',
      parent_id: 1,
      active: true,
    },
  ])

  attribute = {
    "name": "mts_5597",
    "display": "mts_5597",
    "tag": "multi_tree_select",
    "null": true,
    "nulloption": true,
    "translate": true,
    "relation": "Group",
    "filter": ['', '2'],
    "value": 2,
    "multiple": true,
  }

  element = App.UiElement.multi_tree_select.render(attribute)

  assert.equal(true, element.find(".token[data-value='2']").length == 1)

  el.append(element)
});
