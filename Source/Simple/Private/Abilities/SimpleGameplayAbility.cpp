// Fill out your copyright notice in the Description page of Project Settings.


#include "Abilities/SimpleGameplayAbility.h"

USimpleGameplayAbility::USimpleGameplayAbility()
{
	ReplicationPolicy = EGameplayAbilityReplicationPolicy::ReplicateNo;
	InstancingPolicy = EGameplayAbilityInstancingPolicy::InstancedPerActor;
	NetExecutionPolicy = EGameplayAbilityNetExecutionPolicy::LocalPredicted;
	NetSecurityPolicy = EGameplayAbilityNetSecurityPolicy::ClientOrServer;

	ActivationPolicy = ESimpleAbilityActivationPolicy::OnInputTriggered;
}
