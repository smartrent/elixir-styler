# Copyright 2024 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

defmodule Styler.Config do
  @moduledoc false

  alias Credo.Check.Readability.AliasOrder
  alias Credo.Check.Readability.MaxLineLength
  alias Credo.Check.Readability.ParenthesesOnZeroArityDefs
  alias Styler.Style.Configs

  @key __MODULE__

  @styles [
    Styler.Style.ModuleDirectives,
    Styler.Style.Pipes,
    Styler.Style.SingleNode,
    Styler.Style.Defs,
    Styler.Style.Blocks,
    Styler.Style.Deprecations,
    Configs
  ]

  @stdlib MapSet.new(~w(
    Access Agent Application Atom Base Behaviour Bitwise Code Date DateTime Dict Ecto Enum Exception
    File Float GenEvent GenServer HashDict HashSet Integer IO Kernel Keyword List
    Macro Map MapSet Module NaiveDateTime Node Oban OptionParser Path Port Process Protocol
    Range Record Regex Registry Set Stream String StringIO Supervisor System Task Time Tuple URI Version
  )a)

  def set(config) do
    :persistent_term.get(@key)
    :ok
  rescue
    ArgumentError -> set!(config)
  end

  def set!(config) do
    credo_opts = extract_configs_from_credo()

    excludes =
      config[:alias_lifting_exclude]
      |> List.wrap()
      |> MapSet.new(fn
        atom when is_atom(atom) ->
          case to_string(atom) do
            "Elixir." <> rest -> String.to_atom(rest)
            _ -> atom
          end

        other ->
          raise "Expected an atom for `alias_lifting_exclude`, got: #{inspect(other)}"
      end)
      |> MapSet.union(@stdlib)

    reorder_configs = if is_nil(config[:reorder_configs]), do: true, else: config[:reorder_configs]

    :persistent_term.put(@key, %{
      lifting_excludes: excludes,
      line_length: credo_opts[:line_length] || 98,
      reorder_configs: reorder_configs,
      sort_order: credo_opts[:sort_order] || :alpha,
      zero_arity_parens: credo_opts[:zero_arity_parens] || true
    })
  end

  def set_for_test!(key, value) do
    current_vals = :persistent_term.get(@key, %{})
    :persistent_term.put(@key, Map.put(current_vals, key, value))
  end

  def get(key) do
    @key
    |> :persistent_term.get()
    |> Map.fetch!(key)
  end

  def get_styles() do
    if get(:reorder_configs) == true do
      @styles
    else
      @styles -- [Configs]
    end
  end

  def sort_order() do
    get(:sort_order)
  end

  def line_length() do
    get(:line_length)
  end

  def zero_arity_parens?() do
    get(:zero_arity_parens)
  end

  defp read_credo_config() do
    exec = Credo.Execution.build()
    dir = File.cwd!()
    {:ok, config} = Credo.ConfigFile.read_or_default(exec, dir)
    config
  end

  defp extract_configs_from_credo() do
    Enum.reduce(read_credo_config().checks, %{}, fn
      {AliasOrder, opts}, acc when is_list(opts) ->
        Map.put(acc, :sort_order, opts[:sort_method])

      {MaxLineLength, opts}, acc when is_list(opts) ->
        Map.put(acc, :line_length, opts[:max_length])

      {ParenthesesOnZeroArityDefs, opts}, acc when is_list(opts) ->
        Map.put(acc, :zero_arity_parens, opts[:parens])

      _, acc ->
        acc
    end)
  end
end
